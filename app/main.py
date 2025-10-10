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
from conversation import conversation_manager
from mongodb import mongodb_service
from models import (
    QueryRequest,
    QueryResponse,
    SQLRequest,
    HealthCheckResponse,
    SemanticTerm,
    QueryTemplate,
    ExampleQuery,
    EXAMPLE_QUERIES,
    FeedbackTicketRequest,
    FeedbackTicketResponse
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
# CONVERSATION MODE ENDPOINTS
# ============================================================================

@app.post("/api/conversation/query")
async def conversation_query(request: QueryRequest):
    """
    Execute query in conversation mode with intelligent follow-ups

    This endpoint:
    1. Executes the query like /api/query
    2. Maintains conversation history
    3. Returns intelligent follow-up suggestions
    4. Provides insights and guidance
    """
    start_time = time.time()

    try:
        # Get or create session ID
        session_id = request.session_id if hasattr(request, 'session_id') else f"session_{int(time.time())}"

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

        # Get conversation context if in conversation mode
        previous_sql = None
        previous_query = None
        if session_id:
            history = conversation_manager.get_conversation_history(session_id, limit=5)
            if history and len(history) >= 2:
                # Get the last assistant message which contains SQL
                for msg in reversed(history):
                    if msg.get("role") == "assistant" and "Generated SQL:" in msg.get("content", ""):
                        content = msg.get("content", "")
                        if "Generated SQL:" in content and "Results:" in content:
                            # Extract SQL (everything between "Generated SQL:" and "Results:")
                            sql_part = content.split("Generated SQL:")[1].split("Results:")[0].strip()
                            previous_sql = sql_part
                        if "User asked:" in content:
                            query_part = content.split("User asked:")[1].split("\n")[0].strip().strip('"')
                            previous_query = query_part
                        break

            if previous_sql and previous_query:
                logger.info(f"🔗 Context extracted - Previous query: {previous_query[:50]}...")
                logger.info(f"🔗 Context extracted - Previous SQL: {previous_sql[:100]}...")

        # Execute the query (this runs SQL and gets results)
        result = nl_to_sql_agent.execute_query(
            natural_language_query=request.question,
            include_explanation=request.include_explanation,
            model=request.model,
            skip_ambiguity_check=request.skip_ambiguity_check,
            previous_sql=previous_sql,
            previous_query=previous_query
        )

        # Add execution time
        execution_time = (time.time() - start_time) * 1000
        result["execution_time_ms"] = round(execution_time, 2)

        # If successful, get intelligent follow-ups
        if result.get("success"):
            logger.info(f"Conversation mode: Adding to history for session {session_id}")

            # Add to conversation history
            conversation_manager.add_query_result(
                session_id=session_id,
                query=request.question,
                sql=result.get("sql", ""),
                results=result
            )

            logger.info(f"Conversation mode: Getting intelligent follow-ups for session {session_id}")

            # Get intelligent follow-up suggestions
            followup = await conversation_manager.get_intelligent_followup(
                session_id=session_id,
                query=request.question,
                results=result,
                model=request.model or settings.OPENAI_MODEL
            )

            logger.info(f"Conversation mode: Followup received - insights: {bool(followup.get('insights'))}, suggestions: {len(followup.get('suggestions', []))}")

            # Add follow-up to response
            result["conversation"] = {
                "session_id": session_id,
                "insights": followup.get("insights", ""),
                "suggestions": followup.get("suggestions", []),
                "nudge": followup.get("nudge", ""),
                "history_count": len(conversation_manager.get_conversation_history(session_id))
            }

            logger.info(f"Conversation mode: Response prepared with conversation data")

        return QueryResponse(**result)

    except Exception as e:
        logger.error(f"Conversation query error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/conversation/{session_id}/history")
async def get_conversation_history(session_id: str, limit: int = 10):
    """Get conversation history for a session"""
    try:
        history = conversation_manager.get_conversation_history(session_id, limit)
        summary = conversation_manager.get_session_summary(session_id)

        return {
            "session_id": session_id,
            "history": history,
            "summary": summary
        }
    except Exception as e:
        logger.error(f"Get history error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/conversation/{session_id}")
async def clear_conversation(session_id: str):
    """Clear conversation history for a session"""
    try:
        conversation_manager.clear_session(session_id)
        return {"success": True, "message": f"Conversation {session_id} cleared"}
    except Exception as e:
        logger.error(f"Clear conversation error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# FEEDBACK TICKET ENDPOINTS
# ============================================================================

@app.post("/api/feedback/ticket", response_model=FeedbackTicketResponse)
async def submit_feedback_ticket(request: FeedbackTicketRequest):
    """
    Submit a feedback ticket for incorrect or problematic responses

    Users can report issues with:
    - Incorrect SQL generation
    - Wrong results
    - Performance problems
    - Feature requests
    """
    try:
        # Prepare ticket data
        ticket_data = {
            "session_id": request.session_id,
            "user_query": request.user_query,
            "sql_generated": request.sql_generated,
            "response_data": request.response_data,
            "issue_description": request.issue_description,
            "contact_email": request.contact_email,
            "model_used": request.model_used,
            "execution_time_ms": request.execution_time_ms,
            "row_count": request.row_count
        }

        # Create ticket in MongoDB
        ticket_id = await mongodb_service.create_ticket(ticket_data)

        logger.info(f"Feedback ticket created: {ticket_id} for query: {request.user_query[:50]}...")

        return FeedbackTicketResponse(
            success=True,
            ticket_id=ticket_id,
            message="Feedback ticket submitted successfully. We'll review it and get back to you if you provided contact information.",
            created_at=datetime.utcnow()
        )

    except Exception as e:
        logger.error(f"Error creating feedback ticket: {str(e)}")
        return FeedbackTicketResponse(
            success=False,
            message=f"Failed to submit feedback ticket: {str(e)}"
        )


@app.get("/api/feedback/tickets")
async def get_feedback_tickets(
    status: str = None,
    limit: int = 100,
    skip: int = 0
):
    """
    Get all feedback tickets (admin endpoint)

    Query parameters:
    - status: Filter by status (open/resolved/closed)
    - limit: Maximum tickets to return (default 100)
    - skip: Number of tickets to skip for pagination
    """
    try:
        tickets = await mongodb_service.get_all_tickets(status=status, limit=limit, skip=skip)
        stats = await mongodb_service.get_ticket_stats()

        return {
            "success": True,
            "tickets": tickets,
            "count": len(tickets),
            "stats": stats
        }
    except Exception as e:
        logger.error(f"Error fetching feedback tickets: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/feedback/ticket/{ticket_id}")
async def get_feedback_ticket(ticket_id: str):
    """Get a specific feedback ticket by ID"""
    try:
        ticket = await mongodb_service.get_ticket(ticket_id)

        if not ticket:
            raise HTTPException(status_code=404, detail=f"Ticket {ticket_id} not found")

        return {
            "success": True,
            "ticket": ticket
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching ticket {ticket_id}: {str(e)}")
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

    # Test PostgreSQL connection
    if db_service.test_connection():
        logger.info("✓ PostgreSQL connection successful")
    else:
        logger.error("✗ PostgreSQL connection failed")

    # Connect to MongoDB
    try:
        await mongodb_service.connect()
        logger.info("✓ MongoDB connection successful")
    except Exception as e:
        logger.error(f"✗ MongoDB connection failed: {str(e)}")

    # Check semantic dictionary loaded
    dict_count = len(nl_to_sql_agent.semantic_dictionary)
    template_count = len(nl_to_sql_agent.query_templates)
    logger.info(f"✓ Loaded {dict_count} semantic terms and {template_count} query templates")


@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    logger.info("Shutting down application")

    # Disconnect MongoDB
    await mongodb_service.disconnect()


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
