from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel as PydanticBaseModel
from pydantic import ConfigDict


class ExtendedEnum(Enum):

    @classmethod
    def list(cls):
        return list(map(lambda c: c.value, cls))


class BaseModel(PydanticBaseModel):
    """Base model for all data models"""

    model_config = ConfigDict(
        populate_by_name=True,
        # validate_assignment=True,
        from_attributes=True,
        arbitrary_types_allowed=True,
        protected_namespaces=(),
    )


class LoggerConfiguration(BaseModel):
    """Represents the logger configuration"""

    log_level: str


class ServerConfiguration(BaseModel):
    """Represents the server configuration"""

    host: str
    port: str


class OpenAIConfiguration(BaseModel):
    """Represents the OpenAI configuration"""

    api_key: str
    model_name: str
    embedding_model_name: str
    context_window: int


class AzureAIConfiguration(BaseModel):
    """Represents the AzureAI configuration"""

    api_key: str
    type: str
    base: str
    version: str
    deployment_name: str
    embedding_deployment_name: str
    model_name: str


class PerplexityAIConfiguration(BaseModel):
    """Represents the Perplexity configuration"""

    api_key: str
    model_name: str
    api_base: str


class AnthropicAIConfiguration(BaseModel):
    """Represents the Anthropic configuration"""

    api_key: str
    model_name: str


class GeminiAIConfiguration(BaseModel):
    """Represents the Anthropic configuration"""

    api_key: str
    model_name: str


class APIHandlerConfiguration(BaseModel):
    """Represents the APIHandler configuration"""

    api_config_file: str
    openapi_spec_dir: str


class MongoDBConfiguration(BaseModel):
    """Represents the MongoDB configuration"""

    host: str
    port: int
    username: str
    password: str
    db: str


class PostgreSQLConfiguration(BaseModel):
    """Represents the PostgreSQL configuration"""

    host: str
    port: int
    username: str
    password: str
    db: str
    app_schema: str


class SQLServerConfiguration(BaseModel):
    """Represents the SQLServer configuration"""

    host: str
    port: int
    username: str
    password: str
    db: str
    app_schema: str


class SQLiteConfiguration(BaseModel):
    """Represents the SQLite configuration"""

    db_path: str


class OpenSearchConfiguration(BaseModel):
    """Represents the OpenSearch configuration"""

    host: str
    username: str
    password: str
    use_ssl: bool
    verify_certs: bool
    index_name: str


class LLMResponseFormatConfiguration(BaseModel):
    planner_schema: str
    api_generator_schema: str


class LangfuseConfiguration(BaseModel):
    """Represents the Langfuse configuration"""

    env: str


class CommonConfiguration(BaseModel):
    max_retries: int


class PocketBaseConfiguration(BaseModel):
    """Represents the PocketBase configuration"""

    url: str
    admin_email: str
    admin_password: str


# class AWSConfiguration(BaseModel):
#     """Represents the AWS configuration"""

#     aws_access_key_id: str
#     aws_secret_access_key: str


class PineconeConfiguation(BaseModel):
    """Represents the Pinecone configuration"""

    api_key: str
    index: str
    namespace: str
    spec_cloud: str
    spec_region: str
    metric: str
    timeout: int


class AzureAISearchConfiguration(BaseModel):
    """Represents the AzureAISearch configuration"""

    endpoint: str
    key: str
    index_name: str
    semantic_configuration_name: str


class Configuration(BaseModel):
    """Represents the configuration"""

    application_name: str
    logger_configuration: LoggerConfiguration
    openai_configuration: OpenAIConfiguration
    server_configuration: ServerConfiguration

    azureai_configuration: AzureAIConfiguration
    perplexityai_configuration: PerplexityAIConfiguration
    anthropicai_configuration: AnthropicAIConfiguration
    geminiai_configuration: GeminiAIConfiguration
    api_handler_configuration: APIHandlerConfiguration
    common_configuration: CommonConfiguration
    mongodb_configuration: MongoDBConfiguration
    postgresql_configuration: PostgreSQLConfiguration
    sqlserver_configuration: SQLServerConfiguration
    sqlite_configuration: SQLiteConfiguration
    opensearch_configuration: OpenSearchConfiguration

    pinecone_configuration: PineconeConfiguation

    langfuse_configuration: LangfuseConfiguration
    pocketbase_configuration: PocketBaseConfiguration


class QueryContext(BaseModel):
    """Represents the query context"""

    query: str
    role: str
    stream_response: Any


# region Constants
class LangfuseMetaData(BaseModel):
    generation_name: str
    generation_id: str
    parent_observation_id: str
    version: str
    trace_user_id: str
    session_id: str
    tags: list[str]
    trace_name: str
    trace_id: str
    trace_metadata: dict[str, Any]
    trace_version: str
    trace_release: str
    existing_trace_id: Optional[str] = None
    update_trace_keys: Optional[list[str]] = None
    debug_langfuse: Optional[bool] = None


class Roles(ExtendedEnum):
    "Represents roles"

    admin: str = "Admin"
    basic: str = "Basic"
    Developer: str = "Developer"


class LLMProvider(ExtendedEnum):
    "Represents provider"

    openai: str = "openai"
    bedrock: str = "bedrock"
    azure_openai: str = "azure_openai"
    perplexity_ai: str = "perplexity_ai"
    anthropic_ai: str = "anthropic_ai"
    gemini_ai: str = "gemini_ai"
    lite_llm: str = "lite_llm"


class LiteLLMModels(ExtendedEnum):
    "Represents lite llm models"


class LangfusePrompt(ExtendedEnum):
    "Represents llm prompts"

    search_eval: str = "search_eval"
    search_eval_compare: str = "search_eval_compare"
    global_search: str = "global_search"
    generator: str = "generator"
    sql_agent: str = "sql_agent"
    mongo_agent: str = "mongo_agent"


class DatabaseType(ExtendedEnum):
    "Represents different database types"

    postgresql: str = "postgresql"
    pinecone: str = "pinecone"
    azure_ai_search: str = "azure_ai_search"
    chroma: str = "chroma"


class VectorDBModel(ExtendedEnum):
    pinecone: str = "pinecone"
    azure_ai_search: str = "azure_ai_search"


# endregion
