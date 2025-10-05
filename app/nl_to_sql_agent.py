"""
Natural Language to SQL Agent using OpenAI
"""
from openai import OpenAI
from typing import Dict, Any, List, Optional
import logging
import json

from config import settings
from database import db_service

logger = logging.getLogger(__name__)


class NLToSQLAgent:
    """Agent that converts natural language questions to SQL queries"""

    def __init__(self):
        """Initialize OpenAI client and load context"""
        self.client = OpenAI(
            api_key=settings.OPENAI_API_KEY,
            base_url=settings.OPENAI_API_BASE_URL
        )
        self.semantic_dictionary = None
        self.query_templates = None
        self.view_schemas = None
        self._load_context()

    def _load_context(self):
        """Load semantic dictionary and query templates from database"""
        try:
            self.view_schemas = db_service.get_view_schemas()
            self.semantic_dictionary = db_service.get_semantic_dictionary()
            self.query_templates = db_service.get_query_templates()
            logger.info(f"Loaded schemas for {len(self.view_schemas)} views")
            logger.info(f"Loaded {len(self.semantic_dictionary)} semantic terms")
            logger.info(f"Loaded {len(self.query_templates)} query templates")
        except Exception as e:
            logger.error(f"Failed to load context: {str(e)}")
            self.view_schemas = {}
            self.semantic_dictionary = []
            self.query_templates = []

    def _build_system_prompt(self) -> str:
        """Build system prompt with actual view schemas"""

        # Build view schemas text (ACTUAL COLUMNS - not hardcoded)
        key_views = [
            'vw_patients_2025',
            'vw_patient_annual_costs_2025',
            'vw_patient_conditions_2025',
            'vw_er_visits_2025',
            'vw_patient_er_summary_2025',
            'vw_cancer_prevalence_2025',
            'vw_total_cost_by_month_2025',
            'vw_top100_patients_by_county_2025',
            'vw_patient_procedure_events_2025'
        ]

        schemas_text = ""
        for view_name in key_views:
            if view_name in self.view_schemas:
                columns = ", ".join([f"{col['column']} ({col['type']})" for col in self.view_schemas[view_name]])
                schemas_text += f"\n{view_name}:\n  {columns}\n"

        # Convert templates to readable format
        templates_text = "\n".join([
            f"- Pattern: {t['natural_language_pattern']}\n"
            f"  SQL: {t['sql_template']}\n"
            f"  Example: {t['example_input']} → {t['example_output']}"
            for t in self.query_templates[:10]  # Limit to first 10
        ])

        system_prompt = f"""You are a healthcare analytics SQL expert. Convert natural language questions to PostgreSQL queries.

IMPORTANT RULES:
1. ONLY generate SELECT queries (no INSERT, UPDATE, DELETE, DROP, etc.)
2. Use the views below - reference ONLY the columns that exist in each view
3. CRITICAL: Use exact column names as shown - do not assume or invent column names
4. For year filtering, use WHERE conditions on year columns (when they exist)
5. Return patient_id, never patient names (PHI protection)
6. LIMIT clause usage - DO NOT USE LIMIT:
   - NEVER add LIMIT to queries
   - Return ALL matching records
   - UI will handle pagination and display limits
   - Exception: Only use LIMIT if user explicitly specifies (e.g., "top 10", "first 5")
   - For aggregations (COUNT/SUM/AVG): NO LIMIT needed
7. ORDER BY clause - ALWAYS use intelligent ordering:
   - For rankings/top queries: ORDER BY the metric DESC (highest first)
   - For lists: ORDER BY most relevant column (costs DESC, visits DESC, date DESC)
   - For patient lists: ORDER BY patient_id ASC (consistent ordering)
   - For time-series: ORDER BY date/year ASC (chronological)
   - Examples:
     * "ER frequent flyers" → ORDER BY er_visits DESC
     * "highest costs" → ORDER BY total_cost DESC
     * "patient demographics" → ORDER BY patient_id ASC
     * "monthly trends" → ORDER BY month ASC
8. Generate ONLY the SQL query, no explanations or markdown

FORMATTING & INTELLIGENCE:
- For percentages/rates: ALWAYS round to 2 decimal places using ROUND(value, 2)
- For percentages: Multiply by 100 and add '%' in column alias (e.g., AS "screening_rate_%")
- For monetary values: ROUND to 2 decimal places
- For counts: Keep as integers (no rounding)
- Example: ROUND(COUNT(*) FILTER (WHERE is_screened)::DECIMAL / NULLIF(COUNT(*), 0) * 100, 2) AS "screening_rate_%"

CONDITION QUERIES - IMPORTANT:
- "Show me [condition] patients" → Use vw_patient_conditions_2025 to get patient list
- "Count of [condition] patients" → Use vw_patient_conditions_2025 with COUNT
- "[Condition] prevalence by type" → Use vw_cancer_prevalence_2025 (aggregated)
- Cancer types in data: 'Lung cancer', 'Prostate cancer', 'Colorectal cancer', 'Breast cancer', 'Other cancer'
- For "any cancer" or "all cancer patients": Use WHERE condition_name LIKE '%cancer%'

STATE HANDLING:
- The "state" column stores 2-letter abbreviations (CA, FL, TX, NY, etc.)
- When user says state names (California, Florida, Texas, New York), convert to abbreviations:
  - California → CA
  - Florida → FL
  - Texas → TX
  - New York → NY
  - Illinois → IL
  - Arizona → AZ
  - Washington → WA
  - Use OR conditions to handle both: WHERE state IN ('FL') OR state_abbr = 'FL'

AVAILABLE VIEWS AND THEIR ACTUAL COLUMNS:
{schemas_text}

QUERY TEMPLATES (common patterns):
{templates_text}

EXAMPLE QUERIES:

Q: "How many patients do we have?"
A: SELECT COUNT(*) AS patient_count FROM vw_patients_2025;

Q: "Show me patients in Florida"
A: SELECT patient_id, age_years, gender FROM vw_patients_2025 WHERE state = 'FL' LIMIT 100;

Q: "Show me patients in FL"
A: SELECT patient_id, age_years, gender FROM vw_patients_2025 WHERE state = 'FL' LIMIT 100;

Q: "Show me diabetic patients over 65"
A: SELECT p.patient_id, p.age_years, c.condition_name
FROM vw_patient_conditions_2025 c
JOIN vw_patients_2025 p ON p.patient_sk = c.patient_sk
WHERE c.condition_name IN ('Type 2 diabetes', 'Type 1 diabetes')
  AND p.age_years > 65
LIMIT 100;

Q: "Top 10 most expensive patients"
A: SELECT patient_id, total_cost_2025
FROM vw_patient_annual_costs_2025
ORDER BY total_cost_2025 DESC
LIMIT 10;

Q: "ER frequent flyers"
A: SELECT patient_id, er_visits_2025
FROM vw_patient_er_summary_2025
ORDER BY er_visits_2025 DESC
LIMIT 20;

Q: "Total cost by month"
A: SELECT month, month_name, ROUND(total_allowed_amt, 2) AS total_cost
FROM vw_total_cost_by_month_2025
ORDER BY month;

Q: "What's the osteoporosis screening rate?"
A: SELECT
    COUNT(*) as total_eligible,
    COUNT(*) FILTER (WHERE is_screened) as screened,
    ROUND(COUNT(*) FILTER (WHERE is_screened)::DECIMAL / NULLIF(COUNT(*), 0) * 100, 2) AS "screening_rate_%"
FROM vw_osteoporosis_screening_2025;

Q: "Average cost per patient"
A: SELECT ROUND(AVG(total_cost_2025), 2) AS avg_cost
FROM vw_patient_annual_costs_2025;

Q: "Show me cancer patients by cancer type"
A: SELECT * FROM vw_cancer_prevalence_2025;

Q: "Show me all patients with any type of cancer"
A: SELECT DISTINCT patient_id, condition_name
FROM vw_patient_conditions_2025
WHERE condition_name LIKE '%cancer%'
LIMIT 100;

Q: "How many cancer patients do we have?"
A: SELECT COUNT(DISTINCT patient_id) as cancer_patient_count
FROM vw_patient_conditions_2025
WHERE condition_name LIKE '%cancer%';

Now generate the SQL query for the user's question. Return ONLY the SQL query.
"""
        return system_prompt

    def _check_for_ambiguity(self, query: str, model: Optional[str] = None) -> Dict[str, Any]:
        """
        Check if query is ambiguous and needs clarification

        Returns:
            {
                "is_ambiguous": bool,
                "reason": str,
                "clarification_options": [{"text": str, "refined_query": str}]
            }
        """
        try:
            selected_model = model or settings.OPENAI_MODEL

            system_prompt = """You are an ULTRA-STRICT expert at identifying ambiguous healthcare analytics queries.

Your job is to detect when a user's query is UNCLEAR or could have multiple interpretations.

CRITICAL AMBIGUITIES TO ALWAYS FLAG:
1. "Top/best/frequent" WITHOUT specific metric - ALWAYS FLAG AS AMBIGUOUS
2. "Show me ER frequent flyers" - Frequent by what? Visits? Cost? AMBIGUOUS!
3. "Top 10 patients" - Top by what metric? Cost? Visits? Age? AMBIGUOUS!
4. "Show me diabetes patients" - Which diabetes type? All? Most expensive? AMBIGUOUS!
5. "Cancer patients" - Which cancer type? Newly diagnosed? AMBIGUOUS!
6. "Best performing providers" - Best by what measure? AMBIGUOUS!
7. ANY ranking/superlative without explicit criteria - AMBIGUOUS!

IMPORTANT RULES:
- If query uses "top", "best", "frequent", "worst" WITHOUT stating the metric → is_ambiguous: TRUE
- If query asks for ranking without criteria → is_ambiguous: TRUE
- If query could mean 2+ different things → is_ambiguous: TRUE
- Be STRICT - when in doubt, flag as ambiguous
- Provide 3-4 specific interpretation options when ambiguous

Return ONLY a JSON object:
{
  "is_ambiguous": true/false,
  "reason": "why it's ambiguous (or empty if not)",
  "clarification_options": [
    {"text": "Top 10 by total cost", "refined_query": "Show me the top 10 most expensive t2dm patients"},
    {"text": "Top 10 by ER visits", "refined_query": "Show me t2dm patients with most ER visits"}
  ]
}

Examples:
Input: "Show me the top 10 most t2dm patients"
Output: {"is_ambiguous": true, "reason": "Top 10 by what criteria? Cost, visits, or severity?", "clarification_options": [{"text": "Top 10 by total cost", "refined_query": "Show me the top 10 most expensive t2dm patients"}, {"text": "Top 10 by ER visits", "refined_query": "Show me t2dm patients with most ER visits"}]}

Input: "How many patients have diabetes?"
Output: {"is_ambiguous": false, "reason": "", "clarification_options": []}

Input: "Show me top cancer patients"
Output: {"is_ambiguous": true, "reason": "Top by which metric? And which cancer type?", "clarification_options": [{"text": "Most expensive cancer patients", "refined_query": "Show me the most expensive cancer patients"}, {"text": "Cancer patients by specific type", "refined_query": "Show me patients by cancer type"}]}"""

            # Get max_tokens for this model
            max_tokens = settings.get_max_tokens_for_model(selected_model)

            completion_params = {
                "model": selected_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Check this query: {query}"}
                ]
            }

            # Add temperature only if model supports it
            if settings.supports_temperature(selected_model):
                completion_params["temperature"] = 0.1

            if max_tokens:
                capped_tokens = min(500, max_tokens)
                if settings.uses_max_completion_tokens(selected_model):
                    completion_params["max_completion_tokens"] = capped_tokens
                else:
                    completion_params["max_tokens"] = capped_tokens

            try:
                response = self.client.chat.completions.create(**completion_params)
            except Exception as e:
                # Auto-retry logic for API parameter errors
                error_msg = str(e)

                # If max_tokens not supported, retry with max_completion_tokens
                if "max_tokens" in error_msg and "Use 'max_completion_tokens'" in error_msg and "max_tokens" in completion_params:
                    completion_params.pop("max_tokens", None)
                    completion_params["max_completion_tokens"] = capped_tokens
                    response = self.client.chat.completions.create(**completion_params)
                # If max_completion_tokens failed, retry with max_tokens
                elif "max_completion_tokens" in error_msg and "max_completion_tokens" in completion_params:
                    completion_params.pop("max_completion_tokens", None)
                    completion_params["max_tokens"] = capped_tokens
                    response = self.client.chat.completions.create(**completion_params)
                # If temperature not supported, retry without it
                elif "temperature" in error_msg and "temperature" in completion_params:
                    completion_params.pop("temperature", None)
                    response = self.client.chat.completions.create(**completion_params)
                else:
                    raise

            result_text = response.choices[0].message.content.strip()

            # Parse JSON response
            if result_text.startswith("```json"):
                result_text = result_text.replace("```json", "").replace("```", "").strip()
            elif result_text.startswith("```"):
                result_text = result_text.replace("```", "").strip()

            import json
            result = json.loads(result_text)
            return result

        except Exception as e:
            logger.error(f"Ambiguity check error: {str(e)}")
            # On error, assume not ambiguous
            return {
                "is_ambiguous": False,
                "reason": "",
                "clarification_options": []
            }

    def generate_sql(
        self,
        natural_language_query: str,
        include_explanation: bool = False,
        model: Optional[str] = None,
        skip_ambiguity_check: bool = False
    ) -> Dict[str, Any]:
        """
        Generate SQL from natural language query

        Args:
            natural_language_query: User's question in natural language
            include_explanation: Whether to include explanation of the query
            model: OpenAI model to use (overrides settings)
            skip_ambiguity_check: Skip checking for ambiguity

        Returns:
            Dict with sql, explanation, confidence
        """
        try:
            # Check for ambiguity first
            if not skip_ambiguity_check:
                ambiguity_check = self._check_for_ambiguity(natural_language_query, model)
                if ambiguity_check.get("is_ambiguous"):
                    return {
                        "success": False,
                        "needs_clarification": True,
                        "ambiguity": ambiguity_check,
                        "error": ambiguity_check.get("reason", "Query needs clarification")
                    }
            # Build messages
            messages = [
                {"role": "system", "content": self._build_system_prompt()},
                {"role": "user", "content": natural_language_query}
            ]

            # Use provided model or fallback to settings
            selected_model = model or settings.OPENAI_MODEL

            # Get max_tokens for this specific model
            max_tokens = settings.get_max_tokens_for_model(selected_model)

            # Call OpenAI (or compatible API)
            completion_params = {
                "model": selected_model,
                "messages": messages
            }

            # Add temperature only if model supports it
            if settings.supports_temperature(selected_model):
                completion_params["temperature"] = settings.OPENAI_TEMPERATURE

            # Add token limit with correct parameter name based on model
            if max_tokens:
                try:
                    if settings.uses_max_completion_tokens(selected_model):
                        completion_params["max_completion_tokens"] = max_tokens
                    else:
                        completion_params["max_tokens"] = max_tokens
                except Exception:
                    # Fallback to max_tokens if max_completion_tokens not supported
                    completion_params["max_tokens"] = max_tokens

            try:
                response = self.client.chat.completions.create(**completion_params)
            except Exception as e:
                # Auto-retry logic for API parameter errors
                error_msg = str(e)

                # If max_tokens not supported, retry with max_completion_tokens
                if "max_tokens" in error_msg and "Use 'max_completion_tokens'" in error_msg and "max_tokens" in completion_params:
                    completion_params.pop("max_tokens", None)
                    completion_params["max_completion_tokens"] = max_tokens
                    response = self.client.chat.completions.create(**completion_params)
                # If max_completion_tokens failed, retry with max_tokens
                elif "max_completion_tokens" in error_msg and "max_completion_tokens" in completion_params:
                    completion_params.pop("max_completion_tokens", None)
                    completion_params["max_tokens"] = max_tokens
                    response = self.client.chat.completions.create(**completion_params)
                # If temperature not supported, retry without it
                elif "temperature" in error_msg and "temperature" in completion_params:
                    completion_params.pop("temperature", None)
                    response = self.client.chat.completions.create(**completion_params)
                else:
                    raise

            # Extract SQL
            sql = response.choices[0].message.content.strip()

            # Clean SQL (remove markdown code blocks if present)
            if sql.startswith("```sql"):
                sql = sql.replace("```sql", "").replace("```", "").strip()
            elif sql.startswith("```"):
                sql = sql.replace("```", "").strip()

            # Validate SQL
            is_valid, error_msg = db_service.validate_query(sql)
            if not is_valid:
                return {
                    "success": False,
                    "error": f"Generated query failed validation: {error_msg}",
                    "sql": sql
                }

            # Get explanation if requested
            explanation = None
            if include_explanation:
                explanation = self._explain_query(natural_language_query, sql)

            return {
                "success": True,
                "sql": sql,
                "explanation": explanation,
                "model": selected_model,
                "tokens_used": response.usage.total_tokens
            }

        except Exception as e:
            logger.error(f"SQL generation error: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "error_type": type(e).__name__
            }

    def _explain_query(self, question: str, sql: str) -> str:
        """Generate explanation of the SQL query"""
        try:
            messages = [
                {
                    "role": "system",
                    "content": "You are a helpful assistant that explains SQL queries in simple terms."
                },
                {
                    "role": "user",
                    "content": f"Explain this SQL query in 1-2 sentences for a non-technical user:\n\nQuestion: {question}\n\nSQL: {sql}"
                }
            ]

            # Get max_tokens for explanation
            max_tokens = settings.get_max_tokens_for_model(settings.OPENAI_MODEL)

            completion_params = {
                "model": settings.OPENAI_MODEL,
                "messages": messages
            }

            # Add temperature only if model supports it
            if settings.supports_temperature(settings.OPENAI_MODEL):
                completion_params["temperature"] = 0.3

            if max_tokens:
                capped_tokens = min(200, max_tokens)
                if settings.uses_max_completion_tokens(settings.OPENAI_MODEL):
                    completion_params["max_completion_tokens"] = capped_tokens
                else:
                    completion_params["max_tokens"] = capped_tokens

            try:
                response = self.client.chat.completions.create(**completion_params)
            except Exception as e:
                # Retry without temperature if not supported
                if "temperature" in str(e) and "temperature" in completion_params:
                    completion_params.pop("temperature")
                    response = self.client.chat.completions.create(**completion_params)
                else:
                    raise

            return response.choices[0].message.content.strip()

        except Exception as e:
            logger.error(f"Explanation generation error: {str(e)}")
            return "Unable to generate explanation"

    def execute_query(
        self,
        natural_language_query: str,
        include_explanation: bool = False,
        model: Optional[str] = None,
        skip_ambiguity_check: bool = False
    ) -> Dict[str, Any]:
        """
        Generate SQL from NL query and execute it

        Args:
            natural_language_query: User's question
            include_explanation: Whether to include explanation
            model: OpenAI model to use (overrides settings)
            skip_ambiguity_check: Skip ambiguity checking

        Returns:
            Dict with sql, results, explanation, etc.
        """
        # Generate SQL
        sql_result = self.generate_sql(natural_language_query, include_explanation, model, skip_ambiguity_check)

        if not sql_result.get("success"):
            return sql_result

        # Execute SQL
        query_result = db_service.execute_query(sql_result["sql"])

        # Combine results
        return {
            **sql_result,
            **query_result,
            "natural_language_query": natural_language_query
        }


# Global agent instance
nl_to_sql_agent = NLToSQLAgent()
