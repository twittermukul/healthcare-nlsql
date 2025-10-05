"""
Pydantic models for request/response validation
"""
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from datetime import datetime


class QueryRequest(BaseModel):
    """Request model for natural language query"""
    question: str = Field(..., description="Natural language question", min_length=3)
    include_explanation: bool = Field(default=True, description="Include query explanation")
    max_results: Optional[int] = Field(default=None, description="Maximum results to return")
    model: Optional[str] = Field(default=None, description="OpenAI model to use (gpt-4o, gpt-4o-mini, gpt-5)")
    skip_spell_check: bool = Field(default=False, description="Skip spell checking")
    skip_ambiguity_check: bool = Field(default=False, description="Skip ambiguity checking")


class QueryResponse(BaseModel):
    """Response model for query execution"""
    success: bool
    natural_language_query: Optional[str] = None
    sql: Optional[str] = None
    explanation: Optional[str] = None
    columns: Optional[List[str]] = None
    rows: Optional[List[Dict[str, Any]]] = None
    row_count: Optional[int] = None
    truncated: Optional[bool] = None
    model: Optional[str] = None
    tokens_used: Optional[int] = None
    error: Optional[str] = None
    error_type: Optional[str] = None
    execution_time_ms: Optional[float] = None
    spell_check: Optional[Dict[str, Any]] = None
    needs_confirmation: bool = False
    needs_clarification: bool = False
    ambiguity: Optional[Dict[str, Any]] = None


class SQLRequest(BaseModel):
    """Request model for direct SQL execution"""
    sql: str = Field(..., description="SQL query to execute")
    max_results: Optional[int] = Field(default=None, description="Maximum results to return")


class HealthCheckResponse(BaseModel):
    """Response model for health check"""
    status: str
    database_connected: bool
    semantic_dictionary_loaded: bool
    timestamp: datetime


class SemanticTerm(BaseModel):
    """Model for semantic dictionary term"""
    term: str
    term_type: str
    primary_source: Optional[str]
    column_name: Optional[str]
    description: Optional[str]
    synonyms: Optional[List[str]]
    example_usage: Optional[str]


class QueryTemplate(BaseModel):
    """Model for query template"""
    natural_language_pattern: str
    sql_template: str
    category: str
    description: Optional[str]
    example_input: Optional[str]
    example_output: Optional[str]


class ExampleQuery(BaseModel):
    """Model for example queries"""
    question: str
    description: str
    category: str


# Example queries for users
EXAMPLE_QUERIES = [
    ExampleQuery(
        question="How many patients do we have?",
        description="Get total patient count",
        category="Population Health"
    ),
    ExampleQuery(
        question="Show me the top 10 most expensive patients",
        description="High-cost patient analysis",
        category="Cost Analysis"
    ),
    ExampleQuery(
        question="How many patients have diabetes?",
        description="Diabetes prevalence",
        category="Population Health"
    ),
    ExampleQuery(
        question="Who are the ER frequent flyers?",
        description="High ER utilizers",
        category="Utilization"
    ),
    ExampleQuery(
        question="What's the total cost by month in 2025?",
        description="Monthly cost trends",
        category="Cost Analysis"
    ),
    ExampleQuery(
        question="Show me cancer patients by cancer type",
        description="Cancer prevalence breakdown",
        category="Population Health"
    ),
    ExampleQuery(
        question="What's the osteoporosis screening rate for women 65-75?",
        description="Quality measure analysis",
        category="Quality Measures"
    ),
    ExampleQuery(
        question="Show me patients by gender and age group",
        description="Demographic distribution",
        category="Population Health"
    ),
    ExampleQuery(
        question="What procedures did patient PAT000528 have in 2025?",
        description="Patient-specific procedure history",
        category="Patient Analysis"
    ),
    ExampleQuery(
        question="Show me the top 10 highest cost patients in Los Angeles county",
        description="Geographic cost analysis",
        category="Geographic Analysis"
    )
]
