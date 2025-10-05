## Healthcare Analytics NL→SQL API

FastAPI application that converts natural language questions to SQL queries using OpenAI GPT-4, executes them against your healthcare analytics database, and returns results.

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd app
pip install -r requirements.txt
```

### 2. Configure Environment

Edit `.env` file:

```bash
# REQUIRED: Add your OpenAI API key
OPENAI_API_KEY=sk-...your-key-here

# Choose model (gpt-4o, gpt-4o-mini, or gpt-5)
OPENAI_MODEL=gpt-4o

# Database credentials (should match parent database)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=healthcare_analytics
DB_USER=postgres
DB_PASSWORD=your_password

# API settings (defaults are fine)
API_PORT=8000
```

### 3. Run the Application

```bash
# Development mode (auto-reload)
python main.py

# Or with uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Open the UI

Navigate to: **http://localhost:8000**

## 📡 API Endpoints

### Main Endpoints

- `POST /api/query` - Execute natural language query
- `POST /api/sql` - Execute direct SQL query
- `POST /api/generate-sql` - Generate SQL without executing
- `GET /api/examples` - Get example queries
- `GET /api/health` - Health check

### Documentation

- **Swagger UI**: http://localhost:8000/api/docs
- **ReDoc**: http://localhost:8000/api/redoc

## 🔧 Features

### Natural Language to SQL
- Powered by OpenAI GPT-4
- Uses semantic dictionary from database
- Context-aware query generation
- Automatic query validation

### Security
- SQL injection prevention
- Blocked keywords (DROP, DELETE, etc.)
- Query timeout protection
- Read-only queries enforced

### User Experience
- Beautiful web UI
- Example queries
- SQL explanation
- Copy-to-clipboard
- Real-time results table

## 📝 Example Queries

The API supports questions like:

- "How many patients do we have?"
- "Show me the top 10 most expensive patients"
- "What's the diabetes prevalence?"
- "Who are the ER frequent flyers?"
- "Total cost by month in 2025"
- "Show me cancer patients by type"

## 🏗️ Architecture

```
app/
├── main.py              # FastAPI application
├── config.py            # Configuration management
├── database.py          # Database service
├── nl_to_sql_agent.py   # OpenAI NL→SQL agent
├── models.py            # Pydantic models
├── requirements.txt     # Python dependencies
├── .env                 # Configuration (edit this)
├── static/
│   └── index.html       # Frontend UI
└── README.md           # This file
```

## 🔐 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key (required) | - |
| `OPENAI_MODEL` | GPT model: gpt-4o, gpt-4o-mini, or gpt-5 | gpt-4o |
| `OPENAI_TEMPERATURE` | Model temperature | 0.1 |
| `DB_HOST` | Database host | localhost |
| `DB_PORT` | Database port | 5432 |
| `DB_NAME` | Database name | healthcare_analytics |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | - |
| `API_PORT` | API server port | 8000 |
| `MAX_QUERY_RESULTS` | Max results per query | 1000 |
| `QUERY_TIMEOUT_SECONDS` | Query timeout | 30 |

## 📊 API Usage Examples

### Natural Language Query

```bash
curl -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How many patients have diabetes?",
    "include_explanation": true
  }'
```

### Direct SQL Query

```bash
curl -X POST http://localhost:8000/api/sql \
  -H "Content-Type: application/json" \
  -d '{
    "sql": "SELECT COUNT(*) FROM vw_patients_2025;"
  }'
```

### Generate SQL Only

```bash
curl -X POST http://localhost:8000/api/generate-sql \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Show me ER frequent flyers",
    "include_explanation": true
  }'
```

## 🧪 Testing

```bash
# Health check
curl http://localhost:8000/api/health

# Get examples
curl http://localhost:8000/api/examples

# Get semantic dictionary
curl http://localhost:8000/api/dictionary
```

## 🚨 Troubleshooting

### "OpenAI API key not found"
- Add `OPENAI_API_KEY` to `.env` file
- Get key from https://platform.openai.com/api-keys

### "Database connection failed"
- Verify database is running: `psql -U postgres -d healthcare_analytics`
- Check credentials in `.env`
- Ensure database was deployed (see parent README)

### "No semantic dictionary loaded"
- Database must be deployed first
- Run `../deploy.sh` from parent directory
- Verify tables exist: `SELECT COUNT(*) FROM nlsql_semantic_alias;`

### "CORS errors"
- Update `CORS_ORIGINS` in `.env` with your frontend URL

## 🔄 Development

### Auto-reload on changes
```bash
uvicorn main:app --reload
```

### Custom port
```bash
uvicorn main:app --port 8080
```

### Production deployment
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 📈 Performance Tips

1. **Use semantic views** - Queries on `vw_*` views are faster
2. **Limit results** - Set `max_results` in requests
3. **Cache responses** - Enable `ENABLE_QUERY_CACHE=true`
4. **Connection pooling** - Adjust in `database.py` for production

## 🔒 Security Best Practices

1. **Never commit `.env`** - Already in `.gitignore`
2. **Use environment secrets** - For production deployments
3. **Enable query validation** - `ENABLE_QUERY_VALIDATION=true`
4. **Set query timeouts** - Prevent long-running queries
5. **Use read-only DB user** - Create separate user with SELECT-only

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [OpenAI API Guide](https://platform.openai.com/docs)
- [Parent Database README](../README.md)

## ✅ Success Checklist

- [ ] Database deployed and running
- [ ] `.env` configured with OpenAI key and DB credentials
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] App starts without errors
- [ ] Health check returns "healthy" status
- [ ] Can execute example queries
- [ ] Frontend UI loads at http://localhost:8000

## 🆘 Support

For issues:
1. Check logs in console
2. Verify database connection
3. Test API endpoints with curl
4. Review parent database README

---

**Ready to use!** Start the app and visit http://localhost:8000
