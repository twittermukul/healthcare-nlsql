# Quick Setup Guide

## 📋 Prerequisites

1. **PostgreSQL 12+** installed and running
   ```bash
   # Check if installed
   psql --version

   # Install on macOS
   brew install postgresql@16
   brew services start postgresql@16

   # Install on Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib
   sudo systemctl start postgresql
   ```

2. **Database credentials** ready (username, password, host)

---

## 🚀 Setup Steps

### Step 1: Configure Database Connection

Edit the `.env` file with your database details:

```bash
# Open .env file
nano .env   # or use your favorite editor
```

Update these values:
```bash
DB_HOST=localhost          # Your database host
DB_PORT=5432              # PostgreSQL port (default: 5432)
DB_NAME=healthcare_analytics   # Database name (will be created)
DB_USER=postgres          # Your PostgreSQL username
DB_PASSWORD=your_password_here   # Your PostgreSQL password

# Options
LOAD_SAMPLE_DATA=yes      # yes = load 1000 test patients, no = empty schema
RUN_TESTS=yes            # yes = run validation tests after deployment
```

**Example for local PostgreSQL:**
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=healthcare_analytics
DB_USER=postgres
DB_PASSWORD=mypassword
LOAD_SAMPLE_DATA=yes
RUN_TESTS=yes
```

**Example for remote database:**
```bash
DB_HOST=myserver.example.com
DB_PORT=5432
DB_NAME=healthcare_analytics
DB_USER=admin
DB_PASSWORD=SecurePassword123
LOAD_SAMPLE_DATA=no
RUN_TESTS=no
```

### Step 2: Run Deployment

```bash
# Make sure you're in the NLSQL directory
cd /Users/qcogadvisory/Documents/NLSQL

# Run deployment (will use .env settings)
./deploy.sh
```

The script will:
1. ✅ Check if database exists (create if needed)
2. ✅ Create schema (15 tables, 30+ indexes)
3. ✅ Load reference data (conditions, quality measures, codes)
4. ✅ Create semantic views (20+ views)
5. ✅ Create NL→SQL ontology
6. ✅ Load sample data (if LOAD_SAMPLE_DATA=yes)
7. ✅ Run validation tests (if RUN_TESTS=yes)

---

## ✅ Verify Installation

After deployment completes, verify everything works:

```bash
# Connect to database
psql -U postgres -d healthcare_analytics

# Run a quick test query
SELECT COUNT(*) FROM dim_patient;
-- Should return: 1000 (if sample data loaded)

# Test a semantic view
SELECT gender, age_bucket_10yr, COUNT(*)
FROM vw_patients_2025
GROUP BY gender, age_bucket_10yr
ORDER BY gender, age_bucket_10yr;

# Exit psql
\q
```

---

## 🔧 Troubleshooting

### Problem: "psql: command not found"
**Solution:** PostgreSQL not installed or not in PATH
```bash
# macOS
brew install postgresql@16
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

### Problem: "FATAL: role 'postgres' does not exist"
**Solution:** Create PostgreSQL user
```bash
# macOS (create postgres superuser)
createuser -s postgres

# Linux
sudo -u postgres createuser -s postgres
```

### Problem: "FATAL: password authentication failed"
**Solution:** Check your password in .env file
```bash
# Test connection manually
psql -U postgres -h localhost -d postgres
# If this works, update DB_PASSWORD in .env
```

### Problem: "could not connect to server"
**Solution:** PostgreSQL service not running
```bash
# macOS
brew services start postgresql@16

# Ubuntu/Debian
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Check status
brew services list   # macOS
sudo systemctl status postgresql   # Linux
```

### Problem: "permission denied to create database"
**Solution:** User doesn't have CREATEDB permission
```bash
# Grant permission
psql -U postgres -c "ALTER USER your_user CREATEDB;"

# Or create database manually first
createdb -U postgres healthcare_analytics
# Then set DB_NAME=healthcare_analytics in .env
```

---

## 🎯 What Gets Created

After successful deployment:

### Database Objects
- **9 dimension tables**: patient, provider, facility, payer, date, code, condition_group, quality_measure, county
- **7 fact tables**: claim_line, encounter, diagnosis, quality_event, medication, lab_result, monthly_cost
- **2 bridge tables**: patient_condition_year, patient_attribution
- **20+ views**: All vw_* views for semantic queries
- **4 ontology tables**: semantic_alias, query_templates, entity_relationships, guardrails
- **30+ indexes**: On all critical columns
- **10 sequences**: For surrogate key generation

### Sample Data (if LOAD_SAMPLE_DATA=yes)
- **1,000 patients** (realistic demographics)
- **20 providers** (PCPs + specialists)
- **10 facilities** (hospitals, clinics, ER)
- **5 payer plans** (BCBS, Aetna, United Healthcare, Cigna, Humana)
- **~50,000 claim lines** (visits, procedures, ER, IP)
- **Chronic conditions** (diabetes, HTN, cancer, etc.)
- **Quality events** (screening compliance)
- **Monthly cost rollups** (all 12 months of 2025)
- **1,100 patient attributions** (patient-organization-payer relationships)
  - 1,000 current attributions across 50 organizations
  - 100 historical attributions (patients who changed payers/orgs)

---

## 🔒 Security Notes

1. **Never commit .env to git** - It's already in .gitignore
2. **Use strong passwords** for production databases
3. **Limit database user permissions** to only what's needed
4. **Enable SSL** for remote connections:
   ```bash
   DB_HOST=myserver.com?sslmode=require
   ```

---

## 📚 Next Steps

After setup completes:

1. **Explore the data**
   ```bash
   psql -d healthcare_analytics -f 00_test_queries.sql
   ```

2. **Run example queries**
   ```bash
   psql -d healthcare_analytics
   \i 05_example_queries.sql
   ```

3. **Load production data** (if you skipped sample data)
   - See patterns in `06_sample_data_generator.sql`
   - Load dimensions first, then facts, then aggregates

4. **Build your NL→SQL agent**
   - Use `vw_nlsql_dictionary` for semantic mappings
   - Use `nlsql_query_templates` for query patterns
   - See examples in `05_example_queries.sql`

---

## ⚡ Quick Commands Reference

```bash
# Full deployment with sample data
./deploy.sh

# Connect to database
psql -U postgres -d healthcare_analytics

# Run test queries
psql -d healthcare_analytics -f 00_test_queries.sql

# Backup database
pg_dump -U postgres healthcare_analytics > backup.sql

# Restore database
psql -U postgres -d healthcare_analytics < backup.sql

# Reset database (WARNING: deletes all data)
psql -U postgres -c "DROP DATABASE IF EXISTS healthcare_analytics;"
./deploy.sh
```

---

## 🆘 Getting Help

- **Schema questions**: See [README.md](README.md)
- **Query examples**: See [05_example_queries.sql](05_example_queries.sql)
- **Architecture**: See [SUMMARY.md](SUMMARY.md)
- **PostgreSQL help**: https://www.postgresql.org/docs/

---

## ✅ Success Checklist

After deployment, verify:
- [ ] Database created successfully
- [ ] All tables exist (18 tables)
- [ ] All views work (20+ views)
- [ ] Sample data loaded (if enabled)
- [ ] Test queries return results
- [ ] No errors in deployment log

Check with:
```sql
-- Count tables
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
-- Should return: 18

-- Count views
SELECT COUNT(*) FROM information_schema.views
WHERE table_schema = 'public';
-- Should return: 20+

-- Count patients
SELECT COUNT(*) FROM dim_patient;
-- Should return: 1000 (if sample data loaded)
```

You're all set! 🎉
