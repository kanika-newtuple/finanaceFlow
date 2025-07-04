"""
Example usage of LLM Manager for different providers and models
"""

import asyncio
import os
from typing import List

from LLM.manager import LLMServiceManager
from common.data_model import LLMProvider, LiteLLMModels, LangfuseMetaData


async def example_basic_usage():
    """Example of basic LLM usage with GPT-4o-mini"""
    
    # Initialize LLM service manager
    llm_service_manager = LLMServiceManager()
    
    # Get LLM service with GPT-4o-mini model
    llm_service = llm_service_manager.get_service(
        llm_provider=LLMProvider.lite_llm,
        model_name=LiteLLMModels.gpt_4o_mini.value
    )
    
    # Set up Langfuse metadata for tracking (optional)
    langfuse_metadata = {}
    if os.environ.get("LANGFUSE_PUBLIC_KEY") and os.environ.get("LANGFUSE_SECRET_KEY"):
        langfuse_metadata = LangfuseMetaData(
            trace_name="example_basic_usage",
            trace_user_id="user123",
            mask_input=True
        ).model_dump()
    
    # Create a simple prompt
    prompt = [{"role": "user", "content": "What is the capital of France?"}]
    
    try:
        # Get completion
        response = await llm_service.completion(
            prompt=prompt,
            langfuse_meta_data=langfuse_metadata,
            temperature=0.1,
            max_tokens=100
        )
        
        print(f"Response: {response}")
        return response
    except Exception as e:
        print(f"Error in basic usage: {str(e)}")
        return None


async def example_streaming_usage():
    """Example of streaming LLM usage"""
    
    # Initialize LLM service manager
    llm_service_manager = LLMServiceManager()
    
    # Get LLM service with GPT-4o model
    llm_service = llm_service_manager.get_service(
        llm_provider=LLMProvider.lite_llm,
        model_name=LiteLLMModels.gpt_4o.value
    )
    
    # Set up Langfuse metadata (optional)
    langfuse_metadata = {}
    if os.environ.get("LANGFUSE_PUBLIC_KEY") and os.environ.get("LANGFUSE_SECRET_KEY"):
        langfuse_metadata = LangfuseMetaData(
            trace_name="example_streaming",
            trace_user_id="user123",
            mask_input=False
        ).model_dump()
    
    # Create a prompt
    prompt = [{"role": "user", "content": "Write a short story about a robot learning to paint."}]
    
    try:
        # Get streaming completion
        print("Streaming response:")
        async for chunk in llm_service.acompletion(
            prompt=prompt,
            langfuse_meta_data=langfuse_metadata,
            temperature=0.7,
            max_tokens=200
        ):
            print(chunk, end="", flush=True)
        
        print("\n")
    except Exception as e:
        print(f"Error in streaming usage: {str(e)}")


async def example_embedding_usage():
    """Example of embedding usage"""
    
    # Initialize LLM service manager
    llm_service_manager = LLMServiceManager()
    
    # Get LLM service
    llm_service = llm_service_manager.get_service(
        llm_provider=LLMProvider.lite_llm,
        model_name="text-embedding-3-small"  # Embedding model
    )
    
    # Set up Langfuse metadata (optional)
    langfuse_metadata = {}
    if os.environ.get("LANGFUSE_PUBLIC_KEY") and os.environ.get("LANGFUSE_SECRET_KEY"):
        langfuse_metadata = LangfuseMetaData(
            trace_name="example_embedding",
            trace_user_id="user123",
            mask_input=True
        ).model_dump()
    
    # Documents to embed
    documents = [
        "The quick brown fox jumps over the lazy dog.",
        "Machine learning is a subset of artificial intelligence.",
        "Python is a popular programming language for data science."
    ]
    
    try:
        # Get embeddings
        embeddings = await llm_service.embed(
            model="text-embedding-3-small",
            documents=documents,
            langfuse_meta_data=langfuse_metadata
        )
        
        print(f"Embeddings shape: {len(embeddings.data)} documents")
        
        # Handle different response structures
        if hasattr(embeddings.data[0], 'embedding'):
            print(f"First embedding dimension: {len(embeddings.data[0].embedding)}")
        elif isinstance(embeddings.data[0], dict) and 'embedding' in embeddings.data[0]:
            print(f"First embedding dimension: {len(embeddings.data[0]['embedding'])}")
        else:
            print(f"Embedding response structure: {type(embeddings.data[0])}")
            print(f"First embedding data: {embeddings.data[0]}")
        
        return embeddings
    except Exception as e:
        print(f"Error in embedding usage: {str(e)}")
        return None


async def example_different_providers():
    """Example of using different LLM providers"""
    
    llm_service_manager = LLMServiceManager()
    
    # Example with different models (you would need appropriate API keys set up)
    providers_and_models = [
        (LLMProvider.lite_llm, LiteLLMModels.gpt_4o_mini.value),
        (LLMProvider.lite_llm, LiteLLMModels.gpt_4o.value),
        # (LLMProvider.lite_llm, LiteLLMModels.gemini_flash.value),  # Would need Gemini API key
        # (LLMProvider.lite_llm, LiteLLMModels.bedrock_anthropic_claude_sonnet.value),  # Would need AWS credentials
    ]
    
    prompt = [{"role": "user", "content": "Explain quantum computing in one sentence."}]
    
    for provider, model in providers_and_models:
        try:
            print(f"\nTrying {provider.value} with model {model}:")
            
            llm_service = llm_service_manager.get_service(
                llm_provider=provider,
                model_name=model
            )
            
            # Set up Langfuse metadata (optional)
            langfuse_metadata = {}
            if os.environ.get("LANGFUSE_PUBLIC_KEY") and os.environ.get("LANGFUSE_SECRET_KEY"):
                langfuse_metadata = LangfuseMetaData(
                    trace_name=f"example_{provider.value}_{model.replace('-', '_')}",
                    trace_user_id="user123",
                    mask_input=True
                ).model_dump()
            
            response = await llm_service.completion(
                prompt=prompt,
                langfuse_meta_data=langfuse_metadata,
                temperature=0.1,
                max_tokens=100
            )
            
            print(f"Response: {response}")
            
        except Exception as e:
            print(f"Error with {provider.value}/{model}: {str(e)}")


async def example_pdf_processor_usage():
    """Example of how the PDF processor uses the LLM manager"""
    
    from LLM.pdf_processor import PDFProcessor
    
    # Initialize PDF processor (this internally uses LLM manager)
    pdf_processor = PDFProcessor()
    
    # Example text content (in real usage, this would come from a PDF)
    sample_text = """
    INVOICE
    
    Vendor: TechCorp Solutions
    Address: 123 Tech Street, Silicon Valley, CA 94025
    Contact: support@techcorp.com
    
    Bill To: John Doe
    Address: 456 Main St, Anytown, USA
    
    Invoice Date: 2024-01-15
    Due Date: 2024-02-15
    Invoice #: INV-2024-001
    
    Items:
    - Web Development Services: $2,500.00
    - Server Maintenance: $500.00
    - Domain Registration: $50.00
    
    Total Amount: $3,050.00
    """
    
    try:
        # Process the text using LLM
        result = await pdf_processor.extract_transactions_from_text(sample_text)
        
        print("PDF Processing Result:")
        print(f"Vendor: {result.get('vendor', 'Unknown')}")
        print(f"Total Amount: {result.get('total_amount', 0)}")
        print(f"Transactions: {len(result.get('transactions', []))}")
        
        return result
    except Exception as e:
        print(f"Error in PDF processor usage: {str(e)}")
        return None


async def main():
    """Run all examples"""
    print("=== LLM Manager Usage Examples ===\n")
    
    # Check if OpenAI API key is set
    if not os.environ.get("OPENAI_API_KEY"):
        print("⚠️  Warning: OPENAI_API_KEY not set. Some examples may fail.")
        print("   Set it with: export OPENAI_API_KEY='your-api-key'")
        print()
    
    # Check if Langfuse is configured
    if not (os.environ.get("LANGFUSE_PUBLIC_KEY") and os.environ.get("LANGFUSE_SECRET_KEY")):
        print("ℹ️  Info: Langfuse not configured. Observability features will be disabled.")
        print("   Set with: export LANGFUSE_PUBLIC_KEY='your-key' && export LANGFUSE_SECRET_KEY='your-secret'")
        print()
    
    print("1. Basic Usage:")
    await example_basic_usage()
    
    print("\n2. Streaming Usage:")
    await example_streaming_usage()
    
    print("\n3. Embedding Usage:")
    await example_embedding_usage()
    
    print("\n4. Different Providers:")
    await example_different_providers()
    
    print("\n5. PDF Processor Usage:")
    await example_pdf_processor_usage()


if __name__ == "__main__":
    # Make sure you have the required environment variables set
    # OPENAI_API_KEY for OpenAI models
    # GOOGLE_API_KEY for Gemini models
    # AWS credentials for Bedrock models
    
    asyncio.run(main()) 