"""
LLM-powered intelligent spell checker for healthcare analytics queries
"""
from typing import Dict
import json
import logging
from openai import OpenAI

from config import settings
from database import db_service

logger = logging.getLogger(__name__)


class SpellChecker:
    """LLM-powered intelligent spell checker"""

    def __init__(self):
        """Initialize spell checker with OpenAI client"""
        self.client = OpenAI(
            api_key=settings.OPENAI_API_KEY,
            base_url=settings.OPENAI_API_BASE_URL
        )
        self.medical_terms = []
        self.location_terms = []
        self._load_vocabulary()

    def _load_vocabulary(self):
        """Load domain-specific vocabulary from database for context"""
        try:
            # Load medical conditions
            result = db_service.execute_query(
                "SELECT DISTINCT group_name FROM dim_condition_group WHERE is_active = true LIMIT 100"
            )
            if result.get("success"):
                self.medical_terms = [
                    row["group_name"]
                    for row in result["rows"]
                    if row.get("group_name")
                ]

            # Load locations (counties)
            result = db_service.execute_query(
                "SELECT DISTINCT county_name FROM dim_patient WHERE county_name IS NOT NULL LIMIT 50"
            )
            if result.get("success"):
                self.location_terms = [
                    row["county_name"]
                    for row in result["rows"]
                    if row.get("county_name")
                ]

            logger.info(f"Loaded {len(self.medical_terms)} medical terms, "
                       f"{len(self.location_terms)} location terms for context")

        except Exception as e:
            logger.error(f"Failed to load vocabulary: {str(e)}")

    def check_query(self, query: str) -> Dict:
        """
        Use LLM to intelligently check query for spelling/grammar errors

        Returns:
            {
                "has_errors": bool,
                "corrected_query": str,
                "original_query": str,
                "explanation": str
            }
        """
        try:
            # Build context with domain terms
            medical_context = ", ".join(self.medical_terms[:30])
            location_context = ", ".join(self.location_terms[:20])

            system_prompt = f"""You are an ULTRA-STRICT spell checker for healthcare analytics queries. You ONLY fix obvious typos and misspellings.

Context - Valid medical conditions in our database:
{medical_context}

Context - Valid locations in our database:
{location_context}

CRITICAL RULES - READ CAREFULLY:
1. ONLY flag clear typos/misspellings where letters are wrong or missing
2. DO NOT change grammar (singular vs plural is fine either way)
3. DO NOT change word order or phrasing
4. DO NOT add/remove words
5. DO NOT change "patient" to "patients" or vice versa - BOTH ARE VALID
6. DO NOT change perfectly spelled words to synonyms
7. DO NOT suggest changes unless there's an OBVIOUS spelling error
8. When in doubt, return has_errors: false

Examples of ACTUAL errors to fix:
- "florda" → "florida" (misspelling)
- "diabtes" → "diabetes" (typo)
- "patinet" → "patient" (typo)
- "hsopital" → "hospital" (typo)

Examples of things to LEAVE ALONE:
- "do we have patient with IP" → NO ERROR (singular is valid)
- "show me patient" → NO ERROR (asking for one patient is valid)
- "patients in FL" → NO ERROR (perfectly fine)
- "how many patient" → NO ERROR (colloquial speech is acceptable)

Return ONLY a JSON object:
{{
  "has_errors": true/false,
  "corrected_query": "only change if there's a clear typo",
  "explanation": "only if you fixed an actual misspelling"
}}

Input: "show patients in florda"
Output: {{"has_errors": true, "corrected_query": "show patients in florida", "explanation": "Fixed typo: 'florda' → 'florida'"}}

Input: "do we have patient with IP"
Output: {{"has_errors": false, "corrected_query": "do we have patient with IP", "explanation": ""}}

Input: "patients with diabtes"
Output: {{"has_errors": true, "corrected_query": "patients with diabetes", "explanation": "Fixed typo: 'diabtes' → 'diabetes'"}}

Input: "How many patient do we have"
Output: {{"has_errors": false, "corrected_query": "How many patient do we have", "explanation": ""}}"""

            # Always use gpt-4o-mini for spell checking (fast and cheap)
            spell_check_model = "gpt-4o-mini"
            max_tokens = settings.get_max_tokens_for_model(spell_check_model)

            completion_params = {
                "model": spell_check_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Check this query: {query}"}
                ]
            }

            # Add temperature only if model supports it
            if settings.supports_temperature(spell_check_model):
                completion_params["temperature"] = 0.1

            if max_tokens:
                capped_tokens = min(300, max_tokens)
                if settings.uses_max_completion_tokens(spell_check_model):
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

            result_text = response.choices[0].message.content.strip()

            # Parse JSON response
            # Remove markdown code blocks if present
            if result_text.startswith("```json"):
                result_text = result_text.replace("```json", "").replace("```", "").strip()
            elif result_text.startswith("```"):
                result_text = result_text.replace("```", "").strip()

            result = json.loads(result_text)

            # Add original query
            result["original_query"] = query

            return result

        except Exception as e:
            logger.error(f"Spell check error: {str(e)}")
            # On error, assume no corrections needed
            return {
                "has_errors": False,
                "corrected_query": query,
                "original_query": query,
                "explanation": ""
            }

    def format_suggestion_message(self, check_result: Dict) -> str:
        """Format a user-friendly suggestion message"""
        if not check_result["has_errors"]:
            return ""

        explanation = check_result.get("explanation", "")
        if explanation:
            return f"Suggestion: {explanation}"
        else:
            return "Possible improvements detected in your query."


# Global spell checker instance
spell_checker = SpellChecker()
