# LLM Integration Guide

This directory contains the LLM (Large Language Model) integration components for the application. The system has been refactored to use a unified LLM manager instead of direct API calls.

## Architecture

### Core Components

1. **`manager.py`** - Main LLM service manager
2. **`pdf_processor.py`** - PDF processing using LLM
3. **`example_usage.py`** - Usage examples

### Key Features

- **Provider Agnostic**: Support for multiple LLM providers (OpenAI, Azure OpenAI, Anthropic, Gemini, etc.)
- **Unified Interface**: Single interface for all LLM operations
- **Langfuse Integration**: Built-in observability and tracking
- **Streaming Support**: Async streaming for real-time responses
- **Embedding Support**: Text embedding capabilities

## Usage

### Basic LLM Usage

```python
from LLM.manager import LLMServiceManager
from common.data_model import LLMProvider, LiteLLMModels, LangfuseMetaData

# Initialize LLM service manager
llm_service_manager = LLMServiceManager()

# Get LLM service with specific model
llm_service = llm_service_manager.get_service(
    llm_provider=LLMProvider.lite_llm,
    model_name=LiteLLMModels.gpt_4o_mini.value
)

# Set up Langfuse metadata for tracking
langfuse_metadata = LangfuseMetaData(
    trace_name="my_operation",
    trace_user_id="user123",
    mask_input=True
).model_dump()

# Create prompt
prompt = [{"role": "user", "content": "What is the capital of France?"}]

# Get completion
response = await llm_service.completion(
    prompt=prompt,
    langfuse_meta_data=langfuse_metadata,
    temperature=0.1,
    max_tokens=100
)
```

### Streaming Usage

```python
# Get streaming completion
async for chunk in llm_service.acompletion(
    prompt=prompt,
    langfuse_meta_data=langfuse_metadata,
    temperature=0.7,
    max_tokens=200
):
    print(chunk, end="", flush=True)
```

### Embedding Usage

```python
# Get embeddings
documents = ["Document 1", "Document 2", "Document 3"]
embeddings = await llm_service.embed(
    model="text-embedding-3-small",
    documents=documents,
    langfuse_meta_data=langfuse_metadata
)
```

### PDF Processing

```python
from LLM.pdf_processor import PDFProcessor

# Initialize PDF processor (uses LLM manager internally)
pdf_processor = PDFProcessor()

# Process PDF file
result = await pdf_processor.process_pdf_bill("path/to/bill.pdf")

# Or process text directly
text_content = "Your invoice text here..."
result = await pdf_processor.extract_transactions_from_text(text_content)
```

## Supported Providers and Models

### LLM Providers
- `LLMProvider.openai` - OpenAI API
- `LLMProvider.azure_openai` - Azure OpenAI
- `LLMProvider.anthropic_ai` - Anthropic Claude
- `LLMProvider.gemini_ai` - Google Gemini
- `LLMProvider.bedrock` - AWS Bedrock
- `LLMProvider.perplexity_ai` - Perplexity AI
- `LLMProvider.lite_llm` - LiteLLM (unified interface)

### Available Models
- `LiteLLMModels.gpt_4o` - GPT-4o
- `LiteLLMModels.gpt_4o_mini` - GPT-4o-mini
- `LiteLLMModels.gemini_flash` - Gemini 2.0 Flash
- `LiteLLMModels.bedrock_anthropic_claude_sonnet` - Claude 3.5 Sonnet via Bedrock

## Environment Variables

Set the appropriate API keys for the providers you want to use:

```bash
# OpenAI
export OPENAI_API_KEY="your-openai-api-key"

# Azure OpenAI
export AZURE_API_KEY="your-azure-api-key"
export AZURE_API_BASE="your-azure-endpoint"
export AZURE_API_VERSION="2024-02-15-preview"
export AZURE_DEPLOYMENT_NAME="your-deployment-name"

# Google Gemini
export GEMINI_API_KEY="your-gemini-api-key"

# Anthropic
export ANTHROPIC_API_KEY="your-anthropic-api-key"

# AWS Bedrock (via AWS credentials)
export AWS_ACCESS_KEY_ID="your-aws-access-key"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Langfuse (for observability)
export LANGFUSE_PUBLIC_KEY="your-langfuse-public-key"
export LANGFUSE_SECRET_KEY="your-langfuse-secret-key"
export LANGFUSE_HOST="https://cloud.langfuse.com"
```

## Migration from Direct OpenAI Calls

### Before (Direct OpenAI)
```python
import openai

client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": prompt}],
    temperature=0.1,
    max_tokens=2000
)
result = response.choices[0].message.content
```

### After (LLM Manager)
```python
from LLM.manager import LLMServiceManager
from common.data_model import LLMProvider, LiteLLMModels, LangfuseMetaData

llm_service_manager = LLMServiceManager()
llm_service = llm_service_manager.get_service(
    llm_provider=LLMProvider.lite_llm,
    model_name=LiteLLMModels.gpt_4o_mini.value
)

langfuse_metadata = LangfuseMetaData(
    trace_name="my_operation",
    trace_user_id="user123"
).model_dump()

response = await llm_service.completion(
    prompt=[{"role": "user", "content": prompt}],
    langfuse_meta_data=langfuse_metadata,
    temperature=0.1,
    max_tokens=2000
)
```

## Benefits of the New System

1. **Provider Flexibility**: Easy to switch between different LLM providers
2. **Observability**: Built-in Langfuse integration for tracking and monitoring
3. **Consistency**: Unified interface across all LLM operations
4. **Maintainability**: Centralized LLM configuration and management
5. **Extensibility**: Easy to add new providers and models
6. **Error Handling**: Consistent error handling across providers

## Testing

Run the example usage file to test the LLM integration:

```bash
cd bot_service/src/backend
python -m LLM.example_usage
```

Make sure you have the required environment variables set before running the examples.

## Troubleshooting

### Common Issues

1. **API Key Not Set**: Ensure the appropriate API key is set in environment variables
2. **Model Not Found**: Check that the model name is correct and supported by the provider
3. **Rate Limiting**: Implement retry logic for rate-limited requests
4. **Network Issues**: Check network connectivity and API endpoint accessibility

### Debugging

Enable debug logging to see detailed LLM request/response information:

```python
import logging
logging.getLogger("LLM").setLevel(logging.DEBUG)
```

## Future Enhancements

- Add support for more LLM providers
- Implement caching for embeddings
- Add retry logic with exponential backoff
- Support for function calling
- Add model performance monitoring
- Implement cost tracking and optimization 