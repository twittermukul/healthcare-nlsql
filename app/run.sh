#!/bin/bash

# ============================================================================
# Healthcare Analytics NL→SQL API - Run Script
# ============================================================================

set -e

echo "======================================================================"
echo "Starting Healthcare Analytics NL→SQL API"
echo "======================================================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo ""
    echo "Please create .env file from .env.example:"
    echo "  cp .env.example .env"
    echo ""
    echo "Then edit .env and add your OpenAI API key and database credentials."
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Check for OpenAI API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY not set in .env"
    echo ""
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo "Then add it to .env file:"
    echo "  OPENAI_API_KEY=sk-..."
    exit 1
fi

# Check if database is accessible
echo "Checking database connection..."
if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    echo "✓ Database connection successful"
else
    echo "⚠️  Warning: Cannot connect to database"
    echo "   Please check DB credentials in .env"
    echo ""
fi

# Check if dependencies are installed
if ! python3 -c "import fastapi" > /dev/null 2>&1; then
    echo ""
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
fi

echo ""
echo "======================================================================"
echo "🚀 Starting API Server"
echo "======================================================================"
echo ""
echo "API will be available at:"
echo "  - Frontend UI:    http://localhost:${API_PORT:-8000}"
echo "  - API Docs:       http://localhost:${API_PORT:-8000}/api/docs"
echo "  - Health Check:   http://localhost:${API_PORT:-8000}/api/health"
echo ""
echo "Press Ctrl+C to stop"
echo "======================================================================"
echo ""

# Start the application
python3 main.py
