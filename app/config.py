"""
Configuration management for Healthcare Analytics NL→SQL API
"""
from pydantic_settings import BaseSettings
from typing import List, Optional, Dict
import os


# Model-specific configurations (2025)
MODEL_CONFIGS = {
    # GPT-5 Series (Latest - 2025)
    "gpt-5": {
        "max_tokens": 128000,
        "context_window": 400000,
        "description": "GPT-5 - State of the art reasoning, 400K context",
        "cost_per_1k_input": 1.25,
        "cost_per_1k_output": 10.0,
        "uses_max_completion_tokens": True,  # New parameter name
        "supports_temperature": False  # Only default temperature (1) allowed
    },
    "gpt-5-mini": {
        "max_tokens": 128000,
        "context_window": 400000,
        "description": "GPT-5 Mini - Faster, cheaper variant",
        "cost_per_1k_input": 0.30,
        "cost_per_1k_output": 2.50,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },
    "gpt-5-nano": {
        "max_tokens": 128000,
        "context_window": 400000,
        "description": "GPT-5 Nano - Smallest, fastest GPT-5",
        "cost_per_1k_input": 0.10,
        "cost_per_1k_output": 1.00,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },

    # O-Series Reasoning Models
    "o1": {
        "max_tokens": 100000,
        "context_window": 200000,
        "description": "o1 - Advanced reasoning model",
        "cost_per_1k_input": 15.0,
        "cost_per_1k_output": 60.0,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },
    "o1-mini": {
        "max_tokens": 65536,
        "context_window": 128000,
        "description": "o1 Mini - Fast reasoning",
        "cost_per_1k_input": 3.0,
        "cost_per_1k_output": 12.0,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },
    "o3": {
        "max_tokens": 100000,
        "context_window": 200000,
        "description": "o3 - Latest reasoning model",
        "cost_per_1k_input": 20.0,
        "cost_per_1k_output": 80.0,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },
    "o3-mini": {
        "max_tokens": 100000,
        "context_window": 200000,
        "description": "o3 Mini - Efficient reasoning",
        "cost_per_1k_input": 1.10,
        "cost_per_1k_output": 4.40,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },
    "o4-mini": {
        "max_tokens": 100000,
        "context_window": 200000,
        "description": "o4 Mini - Latest mini reasoning model",
        "cost_per_1k_input": 1.10,
        "cost_per_1k_output": 4.40,
        "uses_max_completion_tokens": True,
        "supports_temperature": False
    },

    # GPT-4 Series (Currently Available)
    "gpt-4o": {
        "max_tokens": 16384,
        "context_window": 128000,
        "description": "GPT-4o - Best quality",
        "cost_per_1k_input": 2.50,
        "cost_per_1k_output": 10.0,
        "uses_max_completion_tokens": False,
        "supports_temperature": True
    },
    "gpt-4o-mini": {
        "max_tokens": 16384,
        "context_window": 128000,
        "description": "GPT-4o Mini - Fast & cheap (RECOMMENDED)",
        "cost_per_1k_input": 0.15,
        "cost_per_1k_output": 0.60,
        "uses_max_completion_tokens": False,
        "supports_temperature": True
    },
    "gpt-4-turbo": {
        "max_tokens": 4096,
        "context_window": 128000,
        "description": "GPT-4 Turbo",
        "cost_per_1k_input": 10.0,
        "cost_per_1k_output": 30.0,
        "uses_max_completion_tokens": False,
        "supports_temperature": True
    },

    # O-Series (Beta - for advanced reasoning)
    "o1-preview": {
        "max_tokens": 32768,
        "context_window": 128000,
        "description": "o1-Preview - Advanced reasoning",
        "cost_per_1k_input": 15.0,
        "cost_per_1k_output": 60.0,
        "uses_max_completion_tokens": False,  # Will auto-retry if needed
        "supports_temperature": False
    }
}


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # OpenAI Configuration
    OPENAI_API_KEY: str
    OPENAI_API_BASE_URL: str = "https://api.openai.com/v1"
    OPENAI_MODEL: str = "gpt-5-mini"
    OPENAI_TEMPERATURE: float = 0.1
    OPENAI_MAX_TOKENS: Optional[int] = None  # Auto-detected per model if not set

    # Database
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "healthcare_analytics"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = ""

    # MongoDB
    MONGODB_HOST: str = "localhost"
    MONGODB_PORT: int = 27017
    MONGODB_DB: str = "nlsql_feedback"

    # API
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    API_RELOAD: bool = True
    API_WORKERS: int = 1

    # CORS
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8000"

    # App
    APP_NAME: str = "Healthcare Analytics NL→SQL API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # Query Settings
    MAX_QUERY_RESULTS: int = 1000
    QUERY_TIMEOUT_SECONDS: int = 30
    ENABLE_QUERY_CACHE: bool = True
    CACHE_TTL_SECONDS: int = 300

    # Security
    ENABLE_QUERY_VALIDATION: bool = True
    ALLOWED_TABLES: str = "dim_patient,vw_patients_2025,vw_patient_annual_costs_2025"
    BLOCKED_KEYWORDS: str = "DROP,DELETE,TRUNCATE,ALTER,CREATE,INSERT,UPDATE"

    def get_max_tokens_for_model(self, model: str) -> Optional[int]:
        """Get max tokens for a specific model"""
        # Use configured value if set
        if self.OPENAI_MAX_TOKENS:
            return self.OPENAI_MAX_TOKENS

        # Otherwise use model-specific default
        config = MODEL_CONFIGS.get(model)
        if config:
            return config["max_tokens"]

        # Fallback for unknown models
        return None

    def uses_max_completion_tokens(self, model: str) -> bool:
        """Check if model uses max_completion_tokens parameter instead of max_tokens"""
        config = MODEL_CONFIGS.get(model)
        if config:
            return config.get("uses_max_completion_tokens", False)
        return False

    def supports_temperature(self, model: str) -> bool:
        """Check if model supports custom temperature values"""
        config = MODEL_CONFIGS.get(model)
        if config:
            return config.get("supports_temperature", True)  # Default to True for older models
        return True

    @property
    def database_url(self) -> str:
        """Get PostgreSQL database URL"""
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    @property
    def cors_origins_list(self) -> List[str]:
        """Get CORS origins as list"""
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    @property
    def allowed_tables_list(self) -> List[str]:
        """Get allowed tables as list"""
        return [table.strip() for table in self.ALLOWED_TABLES.split(",")]

    @property
    def blocked_keywords_list(self) -> List[str]:
        """Get blocked keywords as list"""
        return [keyword.strip().upper() for keyword in self.BLOCKED_KEYWORDS.split(",")]

    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()
