# 🐳 Docker Deployment Guide

Quick guide to deploy the Healthcare Analytics NL→SQL API using Docker.

## Prerequisites

- Docker & Docker Compose installed
- OpenAI API key ([Get one here](https://platform.openai.com/api-keys))

## Quick Start

### 1. Configure Environment

```bash
cp .env.docker .env
```

Edit `.env` and add your OpenAI API key:
```bash
OPENAI_API_KEY=sk-your-actual-key-here
DB_PASSWORD=postgres
```

### 2. Start Services

```bash
docker-compose up -d
```

This starts:
- **PostgreSQL 15** database on port 5432
- **FastAPI** application on port 8000

### 3. Access Application

- **Web UI**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/docs
- **Health Check**: http://localhost:8000/api/health

### 4. Load Your Data (Optional)

If you have existing healthcare data:

```bash
# Copy SQL files to container
docker cp your_schema.sql nlsql-postgres:/tmp/

# Execute SQL
docker-compose exec postgres psql -U postgres -d healthcare_analytics -f /tmp/your_schema.sql
```

Or connect with your local psql:
```bash
psql -h localhost -U postgres -d healthcare_analytics
# Password: postgres (or your custom password)
```

## Docker Services

### Application Container (`app`)

- **Image**: Built from `Dockerfile`
- **Port**: 8000
- **Health Check**: Automatic via `/api/health`
- **Restart Policy**: unless-stopped
- **User**: Non-root (appuser)

### Database Container (`postgres`)

- **Image**: postgres:15-alpine
- **Port**: 5432
- **Volume**: `postgres_data` (persistent)
- **Health Check**: `pg_isready`
- **Restart Policy**: unless-stopped

## Common Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f postgres
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart app
```

### Stop Services

```bash
# Stop (preserves data)
docker-compose down

# Stop and remove volumes (WARNING: deletes database)
docker-compose down -v
```

### Rebuild After Code Changes

```bash
docker-compose up -d --build
```

### Execute Commands in Containers

```bash
# Python shell in app container
docker-compose exec app python

# PostgreSQL shell
docker-compose exec postgres psql -U postgres -d healthcare_analytics

# Bash shell in app container
docker-compose exec app bash
```

### Check Container Status

```bash
docker-compose ps
docker-compose top
```

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | `sk-proj-...` |

### Optional (with defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_MODEL` | `gpt-4o` | AI model to use |
| `OPENAI_TEMPERATURE` | `0.1` | Temperature (if model supports) |
| `DB_PASSWORD` | `postgres` | PostgreSQL password |
| `API_WORKERS` | `1` | Number of uvicorn workers |
| `DEBUG` | `false` | Debug mode |
| `CORS_ORIGINS` | `http://localhost:8000` | CORS allowed origins |
| `MAX_QUERY_RESULTS` | `1000` | Max query results |
| `QUERY_TIMEOUT_SECONDS` | `30` | Query timeout |

## Supported AI Models

Select from dropdown in Web UI:

### GPT-4 Series (Recommended)
- **gpt-4o** - Best quality, supports temperature
- **gpt-4o-mini** - Fast & cheap
- **gpt-4-turbo** - Legacy

### GPT-5 Series (2025)
- **gpt-5** - 400K context, 128K output
- **gpt-5-mini** - 400K context
- **gpt-5-nano** - Fastest

### O-Series (Reasoning)
- **o4-mini** - Latest
- **o3**, **o3-mini** - Advanced
- **o1**, **o1-mini**, **o1-preview** - Original

**Note**: GPT-5 and o-series don't support custom temperature (uses default 1.0 automatically).

## Data Persistence

### PostgreSQL Data

Database data is stored in Docker volume and persists across restarts:

```bash
# View volumes
docker volume ls | grep nlsql

# Inspect volume
docker volume inspect nlsql_postgres_data

# Backup database
docker-compose exec postgres pg_dump -U postgres healthcare_analytics > backup.sql

# Restore database
docker-compose exec -T postgres psql -U postgres healthcare_analytics < backup.sql
```

### Application Logs

Logs are mounted to `./logs` directory on host:

```bash
ls -la logs/
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs app

# Verify configuration
docker-compose config

# Check environment file
cat .env
```

### Database Connection Issues

```bash
# Check postgres is healthy
docker-compose ps postgres

# Test connection
docker-compose exec postgres pg_isready -U postgres

# View postgres logs
docker-compose logs postgres

# Connect manually
docker-compose exec postgres psql -U postgres -d healthcare_analytics -c "SELECT version();"
```

### OpenAI API Errors

```bash
# Verify API key is set
docker-compose exec app env | grep OPENAI_API_KEY

# Test API key
docker-compose exec app python -c "from config import settings; print(settings.OPENAI_API_KEY[:10])"
```

### Port Already in Use

```bash
# Change ports in docker-compose.yml
# For app:
ports:
  - "8001:8000"  # Changed from 8000:8000

# For postgres:
ports:
  - "5433:5432"  # Changed from 5432:5432
```

### Out of Memory

```bash
# Add memory limits to docker-compose.yml
services:
  app:
    mem_limit: 1g
  postgres:
    mem_limit: 2g
```

### Container Keeps Restarting

```bash
# Check health status
docker-compose ps

# View recent logs
docker-compose logs --tail=50 app

# Disable auto-restart temporarily
docker update --restart=no nlsql-app
```

## Production Deployment

### Resource Limits

Add to `docker-compose.yml`:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### Multiple Workers

Update `.env`:
```bash
API_WORKERS=4
```

### HTTPS with Nginx

Create `docker-compose.override.yml`:

```yaml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - app
```

### Docker Swarm

```bash
docker swarm init
docker stack deploy -c docker-compose.yml nlsql
```

## Security Best Practices

1. **Change default passwords**
   ```bash
   DB_PASSWORD=your-strong-password-here
   ```

2. **Use secrets for API keys** (Docker Swarm/Kubernetes)
   ```bash
   docker secret create openai_key -
   # Paste your key, then Ctrl+D
   ```

3. **Enable query validation**
   ```bash
   ENABLE_QUERY_VALIDATION=true
   ```

4. **Network isolation**
   - Containers use isolated bridge network
   - Only expose necessary ports

5. **Run as non-root**
   - App container uses `appuser` (UID 1000)

6. **Read-only filesystem** (optional)
   ```yaml
   services:
     app:
       read_only: true
       tmpfs:
         - /tmp
   ```

## Monitoring

### Health Checks

```bash
# Application health
curl http://localhost:8000/api/health

# Database health
docker-compose exec postgres pg_isready -U postgres

# Container health status
docker-compose ps
```

### Resource Usage

```bash
# All containers
docker stats

# Specific container
docker stats nlsql-app
```

### Logs

```bash
# Follow logs
docker-compose logs -f

# Search logs
docker-compose logs | grep ERROR

# Export logs
docker-compose logs > nlsql-logs.txt
```

## Backup & Restore

### Database Backup

```bash
# Create backup
docker-compose exec postgres pg_dump -U postgres healthcare_analytics | gzip > backup_$(date +%Y%m%d).sql.gz

# Automated daily backup (add to crontab)
0 2 * * * cd /path/to/NLSQL && docker-compose exec -T postgres pg_dump -U postgres healthcare_analytics | gzip > backups/db_$(date +\%Y\%m\%d).sql.gz
```

### Database Restore

```bash
# Restore from backup
gunzip -c backup_20251005.sql.gz | docker-compose exec -T postgres psql -U postgres healthcare_analytics
```

### Full System Backup

```bash
# Backup database + configuration
docker-compose exec postgres pg_dump -U postgres healthcare_analytics > db_backup.sql
cp .env env_backup
tar czf nlsql_backup_$(date +%Y%m%d).tar.gz db_backup.sql env_backup docker-compose.yml
```

## Scaling

### Horizontal Scaling (Multiple Workers)

```bash
# Scale app service
docker-compose up -d --scale app=3

# Add load balancer (nginx)
# See Production Deployment section
```

### Vertical Scaling (More Resources)

Update `docker-compose.yml`:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
```

## Support

### Get Help

```bash
# Check container logs
docker-compose logs -f app

# Test health endpoint
curl -v http://localhost:8000/api/health

# Verify environment
docker-compose config

# Check network
docker network inspect nlsql_nlsql-network
```

### Common Issues

1. **Port conflicts**: Change ports in `docker-compose.yml`
2. **Memory issues**: Add resource limits
3. **Slow startup**: Check database health first
4. **API errors**: Verify `OPENAI_API_KEY` in `.env`

---

**Ready to deploy!** Run `docker-compose up -d` and visit http://localhost:8000
