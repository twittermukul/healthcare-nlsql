"""
Conversation Mode Service for Healthcare Analytics

Provides intelligent, iterative conversations that guide users to insights
using GPT-5's conversational capabilities with context retention.
"""

from typing import Dict, List, Any, Optional
from datetime import datetime
from openai import OpenAI
from config import settings

class ConversationManager:
    """Manages conversational state and intelligent follow-ups"""

    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY, base_url=settings.OPENAI_API_BASE_URL)
        # In-memory storage (could be Redis/DB in production)
        self.conversations: Dict[str, List[Dict]] = {}

    def get_conversation_prompt(self) -> str:
        """System prompt for conversational analytics assistant"""
        return """You are an expert healthcare analytics assistant helping users discover insights from data.

YOUR ROLE:
- Guide users through exploratory data analysis
- Suggest relevant follow-up questions based on results
- Help users discover patterns and insights they might miss
- Nudge toward deeper analysis when appropriate
- Be conversational, helpful, and proactive

CONVERSATION STYLE:
- After showing results, suggest 2-3 relevant follow-up questions
- Point out interesting patterns in the data
- Ask clarifying questions when needed
- Encourage deeper dives into anomalies or trends
- Use healthcare domain knowledge to guide exploration

EXAMPLE CONVERSATION:
User: "How many diabetic patients do we have?"
Assistant: "We have 450 diabetic patients. Interesting insights:
- That's 18% of our total patient population
- Worth exploring:
  1. How do costs compare between Type 1 and Type 2?
  2. What's the ER utilization rate for diabetics vs non-diabetics?
  3. Are there geographic patterns in diabetes prevalence?
Would you like to explore any of these?"

User: "Yes, show me ER utilization"
Assistant: "Diabetic patients average 2.3 ER visits/year vs 0.8 for non-diabetics - a 187% increase!
This suggests:
- Potential gaps in preventive care
- Opportunity for care management programs
Next steps to consider:
  1. Which diabetic patients are the highest ER utilizers?
  2. What are the common reasons for ER visits?
  3. What's the cost impact of this higher utilization?"

REMEMBER:
- Always provide context and interpretation
- Suggest actionable next steps
- Help users think like data analysts
- Be concise but insightful
"""

    def create_session(self, session_id: str) -> None:
        """Initialize a new conversation session"""
        if session_id not in self.conversations:
            self.conversations[session_id] = [
                {"role": "system", "content": self.get_conversation_prompt()}
            ]

    def add_message(self, session_id: str, role: str, content: str) -> None:
        """Add a message to conversation history"""
        self.create_session(session_id)
        self.conversations[session_id].append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })

    def add_query_result(self, session_id: str, query: str, sql: str, results: Dict[str, Any]) -> None:
        """Add query and results to conversation context"""
        self.create_session(session_id)

        # Format results summary for context
        result_summary = f"""User asked: "{query}"
Generated SQL: {sql}
Results: {results.get('row_count', 0)} rows returned
Sample data: {results.get('rows', [])[:3] if results.get('rows') else 'No data'}"""

        self.add_message(session_id, "user", query)
        self.add_message(session_id, "assistant", result_summary)

    async def get_intelligent_followup(
        self,
        session_id: str,
        query: str,
        results: Dict[str, Any],
        model: str = "gpt-5-mini"
    ) -> Dict[str, Any]:
        """
        Generate intelligent follow-up suggestions based on query results

        Returns:
            {
                "insights": str,  # Key insights from the data
                "suggestions": [  # Follow-up questions
                    {"question": str, "reasoning": str},
                    ...
                ],
                "nudge": str  # Guidance toward deeper analysis
            }
        """
        self.create_session(session_id)

        # Build context message with available schema context
        context_msg = f"""The user just executed this query:
Question: "{query}"
SQL: {results.get('sql', '')}
Results: {results.get('row_count', 0)} rows
Sample data: {str(results.get('rows', [])[:5])}

AVAILABLE DATA IN DATABASE (key views and columns):
- vw_patients_2025: patient_id, age_years, age_bucket_category, gender, race, ethnicity, state, county_name
- vw_patient_conditions_2025: patient_id, condition_name (diagnoses)
- vw_patient_monthly_costs_2025: patient_id, month, year, total_cost, paid_amt, er_visits, ip_admits, op_visits
- vw_er_visits_2025: patient_id, visit_date, primary_dx_code, discharge_status, provider_name, facility_name
- vw_patient_er_summary_2025: patient_id, er_visits_2025 (count)
- vw_cancer_prevalence_2025: cancer_type, patient_count, prevalence_rate

CRITICAL RULES:
1. ONLY suggest follow-up questions that can be answered with the available data above
2. DO NOT suggest questions about: follow-up care, readmissions, treatments, procedures, medications, lab results, or anything not in the schema
3. Focus on: demographics, costs, visit patterns, diagnoses, geographic analysis, trending

Based on these results:
1. What are 2-3 key insights or patterns?
2. What are 3 relevant follow-up questions the user should explore (ONLY using available data)?
3. What's one actionable recommendation or deeper analysis to pursue (with available data)?

Return as JSON:
{{
    "insights": "Brief key insights from the data",
    "suggestions": [
        {{"question": "Follow-up question 1", "reasoning": "Why this matters"}},
        {{"question": "Follow-up question 2", "reasoning": "Why this matters"}},
        {{"question": "Follow-up question 3", "reasoning": "Why this matters"}}
    ],
    "nudge": "Recommendation for deeper analysis"
}}"""

        messages = self.conversations[session_id].copy()
        messages.append({"role": "user", "content": context_msg})

        try:
            completion_params = {
                "model": model,
                "messages": messages,
                "temperature": 0.7,  # More creative for suggestions
                "max_tokens": 800
            }

            # Handle model-specific parameters
            if settings.uses_max_completion_tokens(model):
                completion_params["max_completion_tokens"] = completion_params.pop("max_tokens")

            if not settings.supports_temperature(model):
                completion_params.pop("temperature", None)

            response = self.client.chat.completions.create(**completion_params)

            result_text = response.choices[0].message.content.strip()

            # Try to parse JSON
            import json
            try:
                # Remove markdown code blocks if present
                if "```json" in result_text:
                    result_text = result_text.split("```json")[1].split("```")[0].strip()
                elif "```" in result_text:
                    result_text = result_text.split("```")[1].split("```")[0].strip()

                return json.loads(result_text)
            except:
                # Fallback to basic structure
                return {
                    "insights": result_text[:200],
                    "suggestions": [
                        {"question": "Explore deeper patterns", "reasoning": "Based on initial results"}
                    ],
                    "nudge": "Consider diving deeper into this data"
                }

        except Exception as e:
            return {
                "insights": "Unable to generate insights at this time",
                "suggestions": [],
                "nudge": "",
                "error": str(e)
            }

    def get_conversation_history(self, session_id: str, limit: int = 10) -> List[Dict]:
        """Get recent conversation history"""
        if session_id not in self.conversations:
            return []

        # Skip system message, return last N messages
        messages = self.conversations[session_id][1:]  # Skip system prompt
        return messages[-limit:] if messages else []

    def clear_session(self, session_id: str) -> None:
        """Clear conversation history for a session"""
        if session_id in self.conversations:
            del self.conversations[session_id]

    def get_session_summary(self, session_id: str) -> Dict[str, Any]:
        """Get summary of conversation session"""
        if session_id not in self.conversations:
            return {"message_count": 0, "started": None}

        messages = self.conversations[session_id][1:]  # Skip system
        return {
            "message_count": len(messages),
            "started": messages[0].get("timestamp") if messages else None,
            "last_activity": messages[-1].get("timestamp") if messages else None
        }


# Singleton instance
conversation_manager = ConversationManager()
