from enum import Enum
from typing import Any

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
        validate_assignment=True,
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
    port: str
    username: str
    password: str
    db: str


class PostgreSQLConfiguation(BaseModel):
    """Represents the PostgreSQL configuration"""

    host: str
    port: int
    username: str
    password: str
    db: str
    app_schema: str


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
    # aws_configuration: AWSConfiguration
    openai_configuration: OpenAIConfiguration
    server_configuration: ServerConfiguration

    azureai_configuration: AzureAIConfiguration
    # bedrock_configuration: BedrockConfiguration
    perplexityai_configuration: PerplexityAIConfiguration
    anthropicai_configuration: AnthropicAIConfiguration
    geminiai_configuration: GeminiAIConfiguration

    # VectorDBConfiguration: VectorDBConfiguration
    api_handler_configuration: APIHandlerConfiguration
    common_configuration: CommonConfiguration
    # transformer_configuration: TranformerConfiguration
    mongodb_configuration: MongoDBConfiguration
    postgresql_configuration: PostgreSQLConfiguation
    pinecone_configuration: PineconeConfiguation
    # llm_response_format_configuration: LLMResponseFormatConfiguration

    langfuse_configuration: LangfuseConfiguration
    pocketbase_configuration: PocketBaseConfiguration


class QueryContext(BaseModel):
    """Represents the query context"""

    query: str
    role: str
    stream_response: Any


# region Constants


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


class BedrockModelMapping(ExtendedEnum):
    """Represents model name to model ID mapping"""

    Jamba_Instruct: str = "ai21.jamba-instruct-v1:0"
    Jurassic_2_Mid: str = "ai21.j2-mid-v1"
    Jurassic_2_Ultra: str = "ai21.j2-ultra-v1"
    Titan_Text_G1_Express: str = "amazon.titan-text-express-v1"
    Titan_Text_G1_Lite: str = "amazon.titan-text-lite-v1"
    Titan_Text_Premier: str = "amazon.titan-text-premier-v1:0"
    Titan_Embeddings_G1_Text: str = "amazon.titan-embed-text-v1"
    Titan_Embedding_Text_v2: str = "amazon.titan-embed-text-v2:0"
    Titan_Multimodal_Embeddings_G1: str = "amazon.titan-embed-image-v1"
    Titan_Image_Generator_G1_V1: str = "amazon.titan-image-generator-v1"
    Titan_Image_Generator_G1_V2: str = "amazon.titan-image-generator-v2:0"
    Claude_2_0: str = "anthropic.claude-v2"
    Claude_2_1: str = "anthropic.claude-v2:1"
    Claude_3_Sonnet: str = "anthropic.claude-3-sonnet-20240229-v1:0"
    Claude_3_5_Sonnet: str = "anthropic.claude-3-sonnet-20240229-v1:0"
    Claude_3_Haiku: str = "anthropic.claude-3-haiku-20240307-v1:0"
    Claude_3_Opus: str = "anthropic.claude-3-opus-20240229-v1:0"
    Claude_Instant: str = "anthropic.claude-instant-v1"
    Command_14: str = "cohere.command-text-v14"
    Command_Light_15: str = "cohere.command-light-text-v14"
    Command_R: str = "cohere.command-r-v1:0"
    Command_R_Plus: str = "cohere.command-r-plus-v1:0"
    Embed_English_3: str = "cohere.embed-english-v3"
    Embed_Multilingual_3: str = "cohere.embed-multilingual-v3"
    Llama_2_Chat_13B: str = "meta.llama2-13b-chat-v1"
    Llama_2_Chat_70B: str = "meta.llama2-70b-chat-v1"
    Llama_3_8B_Instruct: str = "meta.llama3-8b-instruct-v1:0"
    Llama_3_70B_Instruct: str = "meta.llama3-70b-instruct-v1:0"
    Llama_3_1_8B_Instruct: str = "meta.llama3-1-8b-instruct-v1:0"
    Llama_3_1_70B_Instruct: str = "meta.llama3-1-70b-instruct-v1:0"
    Llama_3_1_405B_Instruct: str = "meta.llama3-1-405b-instruct-v1:0"
    Mistral_7B_Instruct: str = "mistral.mistral-7b-instruct-v0:2"
    Mixtral_8X7B_Instruct: str = "mistral.mixtral-8x7b-instruct-v0:1"
    Mistral_Large: str = "mistral.mistral-large-2402-v1:0"
    Mistral_Large_2_2407: str = "mistral.mistral-large-2407-v1:0"
    Mistral_Small: str = "mistral.mistral-small-2402-v1:0"
    Stable_Diffusion_XL_0: str = "stability.stable-diffusion-xl-v0"
    Stable_Diffusion_XL_1: str = "stability.stable-diffusion-xl-v1"
    Stable_Diffusion_3_Large: str = "stability.sd3-large-v1:0"
    Stable_Image_Ultra: str = "stability.stable-image-ultra-v1:0"
    Stability_Image_Core: str = "stability.stable-image-core-v1:0"


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
