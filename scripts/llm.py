import json
import os
import sys
import time
from tempfile import TemporaryDirectory
from typing import List

from openai import OpenAI

from log import log


def openai_gpt(model: str, count: int, id: int | List[str], prompt: str | List[str], callback, temperature: float = 1.0, max_tokens: int = 1000, batch_output_file: str = None):
    """
    Process a batch of requests using OpenAI's GPT model.

    Args:
        model (str): The model to use for
        count (int): The number of requests.
        id (int | List[str]): The ID for the requests.
        prompt (str | List[str]): The prompt to use for requests.
        callback (callable): A callback function to handle the answered requests.
        temperature (float, optional): The temperature to use for the model. Default is 1.0.
        max_tokens (int, optional): The maximum number of tokens to generate. Default is 1000.
        batch_output_file (str, optional): The batch output file in case an error occurred.
    """
    if model not in ["gpt-4o-mini", "gpt-4.1-nano", "gpt-4.1-mini", "gpt-4.1"]:
        raise Exception(f"Model {model} not supported")

    def handler(lines):
        lines = [line for line in lines if line]

        log.info(f"Processing {len(lines)} responses")
        with log.progress("Processing", total=len(lines)) as progress:
            for line in lines:
                progress.advance()

                response = json.loads(line)
                content = response["response"]["body"]["choices"][0]["message"]["content"]
                callback(response["custom_id"], content)

    if batch_output_file:
        with open(batch_output_file, 'r') as f:
            handler(f.readlines())
        return

    with TemporaryDirectory() as tempdir:
        input_file = os.path.join(tempdir, "input.jsonl")

        batch_json = {
            "custom_id": "",
            "method": "POST",
            "url": "/v1/chat/completions",
            "body": {
                "model": model,
                "temperature": temperature,
                "max_tokens": max_tokens,
                "messages": [
                    {"role": "system", "content": "You are a SQL generator that cannot speak."},
                    {"role": "user", "content": ""}
                ]
            }
        }

        # Create the input file
        with open(input_file, 'w') as f:
            for i in range(count):
                if isinstance(id, list):
                    batch_json["custom_id"] = id[i]
                else:
                    batch_json["custom_id"] = str(id + i)
                if isinstance(prompt, list):
                    batch_json["body"]["messages"][1]["content"] = prompt[i]
                else:
                    batch_json["body"]["messages"][1]["content"] = prompt
                f.write(json.dumps(batch_json) + "\n")

        log.info(f"Processing {count} requests with `{model}` using the following prompt:")
        log.info(json.dumps(batch_json, indent=2))
        log.warn(f"Processing {count} requests with `{model}` will incur charges to your OpenAI account.")
        if not log.confirm("Do you want to continue?"):
            sys.exit(0)

        log.info(f"Starting batch processing with `{model}` ...")
        start = time.time()

        # Create the batch
        client = OpenAI()
        batch_input_file = client.files.create(file=open(input_file, "rb"), purpose="batch")
        batch = client.batches.create(input_file_id=batch_input_file.id, endpoint="/v1/chat/completions", completion_window="24h", metadata={"description": "1k"})
        log.info(f"{model} batch: {batch.id}")
        time.sleep(10)

        # Wait for the batch to complete
        result = client.batches.retrieve(batch.id)
        with log.progress(result.status.capitalize(), count) as progress:
            while result.status != 'completed':
                if result.status == 'failed':
                    raise Exception(f"Batch {batch.id} failed: {result}")

                time.sleep(30)
                try:
                    result = client.batches.retrieve(batch.id)
                    progress.description(result.status.capitalize())
                    if result.request_counts:
                        progress.completed(result.request_counts.completed)
                except Exception as e:
                    log.warn(str(e))

        log.info(f"Batch {batch.id} completed in {int((time.time() - start) / 60)} minutes")

        # Download the output file
        file_response = client.files.content(result.output_file_id)

        # Write the output to a file
        handler(file_response.text.split('\n'))


def llm(model: str, count: int, id: int | List[str], prompt: str | List[str], callback, temperature: float = 1.0, max_tokens: int = 1000, batch_output_file: str = None):
    """
    Process a batch of requests using a LLM model.

    Args:
        model (str): The model to use for
        count (int): The number of requests.
        id (int | List[str]): The ID for the requests.
        prompt (str | List[str]): The prompt to use for requests.
        callback (callable): A callback function to handle the answered requests.
        temperature (float, optional): The temperature to use for the model. Default is 1.0.
        max_tokens (int, optional): The maximum number of tokens to generate. Default is 1000.
        batch_output_file (str, optional): The batch output file in case an error occurred.
    """
    # Check if the model is supported
    model_mapper = {
        "gpt-4o-mini": openai_gpt,
        "gpt-4.1-nano": openai_gpt,
        "gpt-4.1-mini": openai_gpt,
        "gpt-4.1": openai_gpt,
    }
    if model not in model_mapper:
        raise Exception(f"Model {model} not supported")

    if count == 0:
        return

    model_mapper[model](model, count, id, prompt, callback, temperature, max_tokens, batch_output_file)
