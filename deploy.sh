#!/bin/bash

# ============================================================================
# Healthcare Analytics Schema Deployment Script
# Deploys complete NL→SQL optimized star schema with sample data
# ============================================================================

set -e  # Exit on error

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
else
    echo "Warning: .env file not found. Using default values."
    echo "Copy .env.example to .env and update with your credentials."
    echo ""
fi

# Configuration (with defaults)
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-healthcare_analytics}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_PASSWORD="${DB_PASSWORD:-}"
LOAD_SAMPLE_DATA="${LOAD_SAMPLE_DATA:-yes}"
RUN_TESTS="${RUN_TESTS:-yes}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "======================================================================"
echo "Healthcare Analytics Star Schema - Deployment"
echo "======================================================================"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Database: $DB_NAME"
echo "  Host: $DB_HOST:$DB_PORT"
echo "  User: $DB_USER"
echo "  Load Sample Data: $LOAD_SAMPLE_DATA"
echo "  Run Tests: $RUN_TESTS"
echo ""

# Set password environment variable if provided
if [ -n "$DB_PASSWORD" ]; then
    export PGPASSWORD="$DB_PASSWORD"
fi

# Check if database exists
echo -e "${YELLOW}Checking if database exists...${NC}"
if ! psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo -e "${YELLOW}Database $DB_NAME does not exist. Creating...${NC}"
    psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -c "CREATE DATABASE $DB_NAME;"
else
    echo -e "${GREEN}Database $DB_NAME exists.${NC}"
fi

echo ""

# Function to run SQL file
run_sql() {
    local file=$1
    local description=$2

    echo -e "${YELLOW}Running: $file - $description${NC}"

    if [ ! -f "$file" ]; then
        echo -e "${RED}ERROR: File $file not found!${NC}"
        exit 1
    fi

    if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Success: $description${NC}"
    else
        echo -e "${RED}✗ Failed: $description${NC}"
        echo "Check the error above for details."
        exit 1
    fi

    echo ""
}

# Deploy schema and data
echo "======================================================================"
echo "Step 1: Creating schema (tables, indexes, sequences)"
echo "======================================================================"
run_sql "01_schema_ddl.sql" "Core schema DDL"

echo "======================================================================"
echo "Step 2: Loading reference data (conditions, quality measures, codes)"
echo "======================================================================"
run_sql "02_seed_data.sql" "Reference data & code mappings"

echo "======================================================================"
echo "Step 3: Creating semantic views"
echo "======================================================================"
run_sql "03_semantic_views.sql" "LLM-friendly semantic views"

echo "======================================================================"
echo "Step 4: Creating NL→SQL ontology"
echo "======================================================================"
run_sql "04_nlsql_ontology.sql" "NL→SQL dictionary & query templates"

# Load sample data based on config
echo "======================================================================"
echo "Step 5: Sample Data"
echo "======================================================================"
echo ""

if [[ "$LOAD_SAMPLE_DATA" =~ ^[Yy] ]]; then
    run_sql "06_sample_data_generator.sql" "Sample patient & claims data"

    # Run tests if configured
    if [[ "$RUN_TESTS" =~ ^[Yy] ]]; then
        echo "======================================================================"
        echo "Step 6: Running validation tests"
        echo "======================================================================"
        echo ""
        psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -f "00_test_queries.sql"
    fi
else
    echo -e "${YELLOW}Skipping sample data (LOAD_SAMPLE_DATA=no in .env)${NC}"
    echo -e "${YELLOW}Schema is ready for production data load.${NC}"
    echo ""
fi

# Summary
echo ""
echo "======================================================================"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo "======================================================================"
echo ""
echo "Database: $DB_NAME"
echo ""
echo "Tables created:"
echo "  • 9 dimension tables (patient, provider, facility, date, etc.)"
echo "  • 7 fact tables (claims, encounters, diagnoses, etc.)"
echo "  • 2 bridge/aggregate tables (monthly costs, condition flags)"
echo "  • 20+ semantic views (vw_*)"
echo "  • 4 ontology tables (NL→SQL mappings)"
echo ""
echo "Next steps:"
echo "  1. Review sample queries: 05_example_queries.sql"
echo "  2. Load production data (if not using sample data)"
echo "  3. Query using semantic views (vw_patients_2025, vw_patient_annual_costs_2025, etc.)"
echo "  4. Build NL→SQL agent using vw_nlsql_dictionary"
echo ""
echo "Quick verification:"
echo "  psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c 'SELECT * FROM vw_patients_2025 LIMIT 5;'"
echo ""
echo "======================================================================"
