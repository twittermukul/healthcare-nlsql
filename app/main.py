"""
Healthcare Analytics NL→SQL FastAPI Application
"""
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from datetime import datetime
import time
import logging
from pathlib import Path

from config import settings
from database import db_service
from nl_to_sql_agent import nl_to_sql_agent
from spell_checker import spell_checker
from models import (
    QueryRequest,
    QueryResponse,
    SQLRequest,
    HealthCheckResponse,
    SemanticTerm,
    QueryTemplate,
    ExampleQuery,
    EXAMPLE_QUERIES
)

# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Natural Language to SQL API for Healthcare Analytics",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for frontend
static_path = Path(__file__).parent / "static"
if static_path.exists():
    app.mount("/static", StaticFiles(directory=str(static_path)), name="static")


# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def root():
    """Serve frontend HTML"""
    html_file = Path(__file__).parent / "static" / "index.html"
    if html_file.exists():
        return html_file.read_text()
    return """
    <html>
        <head><title>Healthcare Analytics NL→SQL</title></head>
        <body style="font-family: Arial; padding: 40px;">
            <h1>Healthcare Analytics NL→SQL API</h1>
            <p>The API is running. Frontend UI is being loaded...</p>
            <ul>
                <li><a href="/api/docs">API Documentation (Swagger)</a></li>
                <li><a href="/api/health">Health Check</a></li>
                <li><a href="/api/examples">Example Queries</a></li>
            </ul>
        </body>
    </html>
    """


@app.get("/api/health", response_model=HealthCheckResponse)
async def health_check():
    """Health check endpoint"""
    db_connected = db_service.test_connection()

    return HealthCheckResponse(
        status="healthy" if db_connected else "unhealthy",
        database_connected=db_connected,
        semantic_dictionary_loaded=len(nl_to_sql_agent.semantic_dictionary) > 0,
        timestamp=datetime.now()
    )


@app.post("/api/query", response_model=QueryResponse)
async def execute_nl_query(request: QueryRequest):
    """
    Execute natural language query

    Converts natural language question to SQL and executes it
    """
    start_time = time.time()

    try:
        # Check spelling first (unless skipped)
        if not request.skip_spell_check:
            spell_check = spell_checker.check_query(request.question)

            if spell_check["has_errors"]:
                # Return suggestion for user confirmation
                return QueryResponse(
                    success=False,
                    needs_confirmation=True,
                    spell_check=spell_check,
                    natural_language_query=request.question,
                    error=spell_checker.format_suggestion_message(spell_check)
                )

        # Execute query through agent
        result = nl_to_sql_agent.execute_query(
            natural_language_query=request.question,
            include_explanation=request.include_explanation,
            model=request.model,
            skip_ambiguity_check=request.skip_ambiguity_check
        )

        # Add execution time
        execution_time = (time.time() - start_time) * 1000  # Convert to ms
        result["execution_time_ms"] = round(execution_time, 2)

        return QueryResponse(**result)

    except Exception as e:
        logger.error(f"Query execution error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/sql", response_model=QueryResponse)
async def execute_sql(request: SQLRequest):
    """
    Execute direct SQL query

    For advanced users who want to write SQL directly
    """
    start_time = time.time()

    try:
        # Validate query
        is_valid, error_msg = db_service.validate_query(request.sql)
        if not is_valid:
            raise HTTPException(status_code=400, detail=error_msg)

        # Execute query
        result = db_service.execute_query(
            sql=request.sql,
            max_results=request.max_results
        )

        # Add execution time and SQL
        execution_time = (time.time() - start_time) * 1000
        result["execution_time_ms"] = round(execution_time, 2)
        result["sql"] = request.sql

        return QueryResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"SQL execution error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/dictionary", response_model=list[SemanticTerm])
async def get_semantic_dictionary():
    """Get semantic dictionary (term mappings)"""
    return nl_to_sql_agent.semantic_dictionary


@app.get("/api/templates", response_model=list[QueryTemplate])
async def get_query_templates():
    """Get query templates"""
    return nl_to_sql_agent.query_templates


@app.get("/api/examples", response_model=list[ExampleQuery])
async def get_example_queries():
    """Get example queries for users"""
    return EXAMPLE_QUERIES


@app.post("/api/generate-sql")
async def generate_sql_only(request: QueryRequest):
    """
    Generate SQL without executing

    Useful for previewing the query before execution
    """
    try:
        result = nl_to_sql_agent.generate_sql(
            natural_language_query=request.question,
            include_explanation=request.include_explanation,
            model=request.model
        )
        return result
    except Exception as e:
        logger.error(f"SQL generation error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler"""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An error occurred"
        }
    )


# ============================================================================
# STARTUP/SHUTDOWN EVENTS
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")

    # Test database connection
    if db_service.test_connection():
        logger.info("✓ Database connection successful")
    else:
        logger.error("✗ Database connection failed")

    # Check semantic dictionary loaded
    dict_count = len(nl_to_sql_agent.semantic_dictionary)
    template_count = len(nl_to_sql_agent.query_templates)
    logger.info(f"✓ Loaded {dict_count} semantic terms and {template_count} query templates")


@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    logger.info("Shutting down application")


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.API_RELOAD,
        workers=settings.API_WORKERS
    )
