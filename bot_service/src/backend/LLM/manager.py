from typing import Any
import os

import litellm
import tiktoken
from common.data_model import LLMProvider
from common.logger import logger
from litellm import acompletion, aembedding

# Only enable Langfuse callbacks if the required environment variables are set
langfuse_public_key = os.environ.get("LANGFUSE_PUBLIC_KEY")
langfuse_secret_key = os.environ.get("LANGFUSE_SECRET_KEY")
langfuse_host = os.environ.get("LANGFUSE_HOST", "https://cloud.langfuse.com")

if langfuse_public_key and langfuse_secret_key:
    litellm.success_callback = ["langfuse"]
    litellm.failure_callback = ["langfuse"]
    logger.info("Langfuse callbacks enabled")
else:
    logger.info("Langfuse callbacks disabled - missing environment variables")


class CommonLLM:
    def token_counter(self, response: str, model_name: str) -> int:
        try:
            enc = tiktoken.encoding_for_model(model_name)
            return len(enc.encode(response))
        except KeyError as e:  # noqa
            logger.warning(f"Encoding not found for {model_name}, available encodings {tiktoken.list_encoding_names()}!")

    async def gather_chunks(self, async_generator):
        response = ""
        async for chunk in async_generator:
            response += chunk
        return response

    @staticmethod
    def gather_vision_content(prompt: str, images: Any):
        content = [
            {
                "type": "text",
                "text": prompt,
            },
        ]
        for image in images:
            content.append(
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{image}"},
                },
            )
        return content


class LiteLLMService(CommonLLM):
    def __init__(self):
        super().__init__()
        self.model_name = None

    async def completion(self, prompt: str, langfuse_meta_data: dict = {}, **kwargs):
        # Set default values if not provided
        default_params = {
            "temperature": 0,
            "timeout": 600
        }
        
        # Update defaults with provided kwargs
        default_params.update(kwargs)
        
        # Only pass metadata if Langfuse is enabled
        if langfuse_public_key and langfuse_secret_key:
            default_params["metadata"] = langfuse_meta_data
        
        response = await acompletion(
            model=self.model_name, 
            messages=prompt, 
            **default_params
        )
        return response.choices[0].message.content

    async def acompletion(self, prompt: str, langfuse_meta_data: dict = {}, **kwargs):  # noqa: ASYNC900
        # Set default values if not provided
        default_params = {
            "temperature": 0,
            "timeout": 600
        }
        
        # Update defaults with provided kwargs
        default_params.update(kwargs)
        
        # Only pass metadata if Langfuse is enabled
        if langfuse_public_key and langfuse_secret_key:
            default_params["metadata"] = langfuse_meta_data
        
        async for stream_resp in await acompletion(
            model=self.model_name, 
            messages=prompt, 
            stream=True, 
            **default_params
        ):
            if stream_resp.choices and stream_resp.choices[0].delta.content:
                token = stream_resp.choices[0].delta.content
                yield token

    async def embed(self, model: str, documents: list[str], langfuse_meta_data: dict = {}, **kwargs):
        # Only pass metadata if Langfuse is enabled
        if langfuse_public_key and langfuse_secret_key:
            kwargs["metadata"] = langfuse_meta_data
            
        response = await aembedding(model, input=documents, **kwargs)
        return response

    def set_client_by_model(self, model_name: str, **kwargs):
        self.model_name = model_name


# LiteLLMServiceManager example usage
# llm_service = LLMServiceManager()
# llm = llm_service.get_service(LLMProvider.lite_llm, model_name=LiteLLMModels.gemini_flash.value)
# response = await llm.completion(prompt=[{"role": "user", "content": "write code for saying hi from LiteLLM"}],langfuse_meta_data=LangfuseMetaData(trace_user_id="1234", trace_name="test",mask_input=True).model_dump())

class LLMServiceManager:

    def __init__(self):
        super().__init__()
        self._litellm_service = LiteLLMService()

    def litellm_service(self):
        return self._litellm_service

    def get_service(self, llm_provider: LLMProvider, model_name: str, **kwargs) -> LiteLLMService:
        match llm_provider:

            case LLMProvider.lite_llm:
                self._litellm_service = LiteLLMService()
                self._litellm_service.set_client_by_model(model_name=model_name, **kwargs)
                return self._litellm_service
