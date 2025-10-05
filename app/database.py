"""
Database connection and query execution
"""
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
from typing import List, Dict, Any, Optional
import logging
from contextlib import contextmanager

from config import settings

logger = logging.getLogger(__name__)


class DatabaseService:
    """Database service for executing SQL queries"""

    def __init__(self):
        """Initialize database connection"""
        self.engine = create_engine(
            settings.database_url,
            poolclass=NullPool,  # Disable connection pooling for now
            echo=settings.DEBUG,
        )
        self.SessionLocal = sessionmaker(bind=self.engine)

    @contextmanager
    def get_session(self):
        """Get database session context manager"""
        session = self.SessionLocal()
        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()

    def execute_query(
        self,
        sql: str,
        max_results: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Execute SQL query and return results

        Args:
            sql: SQL query to execute
            max_results: Maximum number of results to return

        Returns:
            Dict with columns and rows
        """
        try:
            with self.get_session() as session:
                # Set statement timeout
                session.execute(
                    text(f"SET statement_timeout = '{settings.QUERY_TIMEOUT_SECONDS}s'")
                )

                # Execute query
                result = session.execute(text(sql))

                # Get column names
                columns = list(result.keys())

                # Fetch results
                limit = max_results or settings.MAX_QUERY_RESULTS
                rows = result.fetchmany(limit)

                # Convert to list of dicts
                data = [dict(zip(columns, row)) for row in rows]

                return {
                    "success": True,
                    "columns": columns,
                    "rows": data,
                    "row_count": len(data),
                    "truncated": len(data) >= limit
                }

        except Exception as e:
            logger.error(f"Query execution error: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "error_type": type(e).__name__
            }

    def get_view_schemas(self) -> Dict[str, List[Dict[str, str]]]:
        """Get actual column schemas for all vw_* views"""
        sql = """
            SELECT
                table_name,
                column_name,
                data_type
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name LIKE 'vw_%'
            ORDER BY table_name, ordinal_position;
        """
        try:
            with self.get_session() as session:
                result = session.execute(text(sql))
                rows = result.fetchall()

                # Group by view name
                schemas = {}
                for row in rows:
                    view_name = row[0]
                    if view_name not in schemas:
                        schemas[view_name] = []
                    schemas[view_name].append({
                        "column": row[1],
                        "type": row[2]
                    })

                logger.info(f"Loaded schemas for {len(schemas)} views")
                return schemas
        except Exception as e:
            logger.error(f"Failed to load view schemas: {str(e)}")
            return {}

    def get_semantic_dictionary(self) -> List[Dict[str, Any]]:
        """Get NL→SQL semantic dictionary from database"""
        sql = """
            SELECT
                term,
                term_type,
                primary_source,
                column_name,
                filter_logic,
                aggregation,
                description,
                synonyms,
                example_usage
            FROM nlsql_semantic_alias
            WHERE is_active = TRUE
            ORDER BY term_type, term;
        """
        result = self.execute_query(sql)
        return result.get("rows", [])

    def get_query_templates(self) -> List[Dict[str, Any]]:
        """Get query templates from database"""
        sql = """
            SELECT
                natural_language_pattern,
                sql_template,
                category,
                description,
                example_input,
                example_output
            FROM nlsql_query_templates
            WHERE is_active = TRUE;
        """
        result = self.execute_query(sql)
        return result.get("rows", [])

    def validate_query(self, sql: str) -> tuple[bool, Optional[str]]:
        """
        Validate SQL query for security

        Returns:
            (is_valid, error_message)
        """
        if not settings.ENABLE_QUERY_VALIDATION:
            return True, None

        sql_upper = sql.upper()

        # Check for blocked keywords
        for keyword in settings.blocked_keywords_list:
            if keyword in sql_upper:
                return False, f"Query contains blocked keyword: {keyword}"

        # Check for multiple statements (SQL injection prevention)
        if ";" in sql and not sql.strip().endswith(";"):
            return False, "Multiple SQL statements not allowed"

        return True, None

    def test_connection(self) -> bool:
        """Test database connection"""
        try:
            with self.get_session() as session:
                session.execute(text("SELECT 1"))
            return True
        except Exception as e:
            logger.error(f"Database connection test failed: {str(e)}")
            return False


# Global database service instance
db_service = DatabaseService()
