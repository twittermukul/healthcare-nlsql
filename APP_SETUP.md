## 🚀 Healthcare Analytics NL→SQL Application Setup

Complete guide to set up and run the FastAPI application with OpenAI integration.

---

## 📋 Prerequisites

1. ✅ **Database deployed** - Run `./deploy.sh` from parent directory first
2. ✅ **Python 3.9+** installed
3. ✅ **OpenAI API key** - Get from https://platform.openai.com/api-keys

---

## 🏗️ Application Structure

```
app/
├── main.py                 # FastAPI application
├── config.py              # Configuration settings
├── database.py            # Database connection service
├── nl_to_sql_agent.py     # OpenAI NL→SQL agent
├── models.py              # Request/response models
├── requirements.txt       # Python dependencies
├── run.sh                 # Quick start script
├── .env                   # YOUR CONFIG (edit this)
├── .env.example           # Config template
├── static/
│   └── index.html         # Web UI
└── README.md             # Documentation
```

---

## ⚡ Quick Start (3 Steps)

### Step 1: Install Dependencies

```bash
cd app
pip install -r requirements.txt
```

**Alternative: Use virtual environment (recommended)**
```bash
cd app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Step 2: Configure Environment

Edit `app/.env` file:

```bash
nano .env  # or use your favorite editor
```

**Required settings:**
```bash
# CRITICAL: Add your OpenAI API key
OPENAI_API_KEY=sk-proj-...your-key-here...

# Choose model (gpt-4o recommended)
OPENAI_MODEL=gpt-4o
# Or use: gpt-4o-mini (cheaper, faster)
# Or use: gpt-5 (when available)

# Database (same as parent database)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=healthcare_analytics
DB_USER=postgres
DB_PASSWORD=your_db_password

# Optional: Advanced settings
API_PORT=8000
OPENAI_TEMPERATURE=0.1
MAX_QUERY_RESULTS=1000
```

### Step 3: Run the Application

**Option A: Using run script (easiest)**
```bash
./run.sh
```

**Option B: Direct Python**
```bash
python main.py
```

**Option C: Using uvicorn**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🌐 Access the Application

Once started, open your browser:

| URL | Description |
|-----|-------------|
| **http://localhost:8000** | 🎨 Main Web UI |
| **http://localhost:8000/api/docs** | 📚 Interactive API Docs (Swagger) |
| **http://localhost:8000/api/health** | ❤️ Health Check |

---

## 🔑 Getting OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign in or create account
3. Click "Create new secret key"
4. Copy the key (starts with `sk-`)
5. Add to `.env` file:
   ```bash
   OPENAI_API_KEY=sk-proj-...your-key...
   ```

**Cost:** ~$0.01-0.10 per query (GPT-4 Turbo)

---

## 💬 Using the Application

### Web UI

1. Open http://localhost:8000
2. Choose from example questions or type your own
3. Click "Execute"
4. View SQL query, explanation, and results table

### Example Questions

Try these:
- "How many patients do we have?"
- "Show me the top 10 most expensive patients"
- "What's the diabetes prevalence?"
- "Who are the ER frequent flyers?"
- "Total cost by month in 2025"
- "Show me cancer patients by type"

### API (curl examples)

**Natural Language Query:**
```bash
curl -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How many patients have diabetes?",
    "include_explanation": true
  }'
```

**Direct SQL:**
```bash
curl -X POST http://localhost:8000/api/sql \
  -H "Content-Type: application/json" \
  -d '{
    "sql": "SELECT COUNT(*) FROM vw_patients_2025;"
  }'
```

**Generate SQL Only (no execution):**
```bash
curl -X POST http://localhost:8000/api/generate-sql \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Show me diabetic patients",
    "include_explanation": true
  }'
```

---

## 🔧 Configuration Options

### Database Settings

```bash
DB_HOST=localhost          # Database server
DB_PORT=5432              # PostgreSQL port
DB_NAME=healthcare_analytics  # Database name
DB_USER=postgres          # Database user
DB_PASSWORD=secret        # Database password
```

### OpenAI Settings

```bash
OPENAI_API_KEY=sk-...     # Your API key (required)
OPENAI_MODEL=gpt-4-turbo-preview  # Model to use
OPENAI_TEMPERATURE=0.1    # 0.0-1.0 (lower = more deterministic)
```

**Available Models:**
- `gpt-4-turbo-preview` - Best quality, higher cost
- `gpt-4` - Stable, good quality
- `gpt-3.5-turbo` - Faster, cheaper (may be less accurate)

### API Settings

```bash
API_HOST=0.0.0.0          # Bind address
API_PORT=8000             # Server port
API_RELOAD=true           # Auto-reload on code changes
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
```

### Security Settings

```bash
ENABLE_QUERY_VALIDATION=true  # Prevent dangerous queries
BLOCKED_KEYWORDS=DROP,DELETE,TRUNCATE,ALTER,CREATE,INSERT,UPDATE
MAX_QUERY_RESULTS=1000        # Limit results per query
QUERY_TIMEOUT_SECONDS=30      # Max query execution time
```

---

## 🧪 Testing & Verification

### 1. Health Check
```bash
curl http://localhost:8000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "database_connected": true,
  "semantic_dictionary_loaded": true,
  "timestamp": "2025-01-15T10:30:00"
}
```

### 2. Test Query
```bash
curl -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{"question": "How many patients?"}'
```

### 3. View Examples
```bash
curl http://localhost:8000/api/examples | jq
```

---

## 🚨 Troubleshooting

### Problem: "OpenAI API key not found"

**Solution:**
```bash
# Check .env file exists
ls -la .env

# Verify key is set
grep OPENAI_API_KEY .env

# Should show: OPENAI_API_KEY=sk-...
```

### Problem: "Database connection failed"

**Solution:**
```bash
# Test database directly
psql -U postgres -h localhost -d healthcare_analytics

# If fails, check:
1. Database is running: brew services list | grep postgresql
2. Credentials in .env match database
3. Database was deployed: ls -la ../01_schema_ddl.sql
```

### Problem: "Semantic dictionary not loaded"

**Solution:**
```bash
# Verify database has semantic data
psql -d healthcare_analytics -c "SELECT COUNT(*) FROM nlsql_semantic_alias;"

# If returns 0 or error, deploy database first:
cd ..
./deploy.sh
```

### Problem: "Module not found" errors

**Solution:**
```bash
# Install dependencies
pip install -r requirements.txt

# Or with virtual environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Problem: "Port 8000 already in use"

**Solution:**
```bash
# Change port in .env
echo "API_PORT=8001" >> .env

# Or kill existing process
lsof -ti:8000 | xargs kill -9
```

### Problem: "CORS errors in browser"

**Solution:**
```bash
# Add your frontend URL to .env
CORS_ORIGINS=http://localhost:3000,http://localhost:8000,http://your-domain.com
```

---

## 📊 How It Works

### Flow Diagram

```
User Question
    ↓
Frontend UI (index.html)
    ↓
FastAPI Endpoint (/api/query)
    ↓
NL→SQL Agent (nl_to_sql_agent.py)
    ↓
OpenAI GPT-4 (with semantic context)
    ↓
Generated SQL Query
    ↓
Query Validation (security)
    ↓
Database Execution (database.py)
    ↓
Results + Explanation
    ↓
Frontend Display
```

### Key Components

1. **main.py** - FastAPI app, endpoints, CORS
2. **nl_to_sql_agent.py** - OpenAI integration, prompt building
3. **database.py** - PostgreSQL connection, query execution
4. **config.py** - Environment configuration
5. **models.py** - Request/response schemas
6. **static/index.html** - Web UI

---

## 🔒 Security Features

✅ **Query Validation** - Blocks DROP, DELETE, etc.
✅ **SQL Injection Prevention** - Parameterized queries
✅ **Timeout Protection** - 30-second query limit
✅ **Result Limits** - Max 1000 rows
✅ **Read-Only** - No data modification allowed
✅ **Environment Secrets** - Credentials in .env (not committed)

---

## 📈 Performance Tips

1. **Use GPT-4 Turbo** - Faster than GPT-4, similar quality
2. **Lower temperature** - Use 0.1 for more consistent SQL
3. **Connection pooling** - Adjust in `database.py` for production
4. **Cache responses** - Set `ENABLE_QUERY_CACHE=true`
5. **Limit results** - Use `max_results` parameter

---

## 🚀 Production Deployment

### Using Gunicorn (recommended)

```bash
# Install gunicorn
pip install gunicorn

# Run with workers
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Using Docker

```bash
# Build image
docker build -t nlsql-api .

# Run container
docker run -d -p 8000:8000 --env-file .env nlsql-api
```

### Environment Variables (Production)

```bash
# Use secrets manager for production
export OPENAI_API_KEY=$(aws secretsmanager get-secret-value --secret-id openai-key --query SecretString --output text)
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id db-password --query SecretString --output text)

# Or use .env.production
cp .env.example .env.production
# Edit with production values
```

---

## ✅ Setup Checklist

- [ ] Python 3.9+ installed
- [ ] Database deployed (parent `deploy.sh` run successfully)
- [ ] OpenAI API key obtained
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] `.env` configured with API key and DB credentials
- [ ] Application starts without errors (`./run.sh`)
- [ ] Health check returns "healthy"
- [ ] Can execute example queries in UI
- [ ] API docs accessible at `/api/docs`

---

## 📚 Resources

- [App README](app/README.md) - Detailed API documentation
- [Parent README](../README.md) - Database schema documentation
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [OpenAI API Docs](https://platform.openai.com/docs)

---

## 🎉 Success!

If everything is working:

✅ Visit http://localhost:8000
✅ Try example queries
✅ View generated SQL
✅ Export results

**Next steps:**
- Customize example queries
- Add custom endpoints
- Deploy to production
- Integrate with your apps

---

**Need help?** Check the troubleshooting section or review logs in the console.
