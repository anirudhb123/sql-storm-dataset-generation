#!/usr/bin/env python3
import argparse
import os
import sys

import simplejson as json
import yaml

from llm import llm
from log import log


def write_query_to_file(sql: str, dest_dir: str, filename: str, postfix: str = ".sql"):
    """
    Writes a SQL query to a file.

    Args:
        sql (str): The SQL query to write.
        dest_dir (str): The directory to write the file to.
        filename (str): The filename.
        postfix (str): The file extension to use.
    """
    if sql.startswith("```"):
        sql = sql.removeprefix("```").removesuffix("```")
    if sql.startswith("sql"):
        sql = sql.removeprefix("sql")
    if sql.startswith("\\n"):
        sql = sql.removeprefix("\\n")

    with open(os.path.join(dest_dir, f"{filename}{postfix}"), 'w') as f:
        f.write(sql)


def write_gpt_queries(dest_dir: str, lines: list[str], postfix: str = ".sql"):
    """
    Writes the queries to files.

    Args:
        dest_dir (str): The directory to write the SQL files to.
        lines (list[str]): The list of query lines.
        postfix (str): The file extension to use.
    """
    lines = [line for line in lines if line]

    log.info(f"Writing {len(lines)} queries to files in `{dest_dir}`")
    with log.progress("Writing queries", total=len(lines)) as progress:
        for i, line in enumerate(lines):
            progress.advance()

            response = json.loads(line)
            sql = response["response"]["body"]["choices"][0]["message"]["content"]
            id = response["custom_id"]

            write_query_to_file(sql, dest_dir, id, postfix)


def main():
    """
    Main function to generate SQL queries based on the provided prompt and dataset.
    """
    log.header("Generate SQL Queries")

    # Parse command line arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument("prompt", help="Prompt to use for generating queries for a benchmark")
    argparser.add_argument("dataset", help="Dataset of the benchmark")
    argparser.add_argument("version", help="Version of the benchmark")
    argparser.add_argument("-b", "--batch_output_file", help="Batch output file in case an error occurred", default=None)
    args = argparser.parse_args()

    prompt_file = os.path.join("prompts", args.prompt + ".yaml")
    dataset_file = os.path.join("prompts", args.dataset + ".yaml")
    dest_dir = os.path.join(args.version, args.dataset, "queries_generated")

    # Check if the prompt and dataset files exist
    if not os.path.exists(prompt_file):
        raise Exception(f"Prompt file {prompt_file} does not exist")
    if not os.path.exists(dataset_file):
        raise Exception(f"Dataset file {dataset_file} does not exist")

    # Create the destination directory if it doesn't exist
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)

    # Load the prompt and dataset files
    with open(prompt_file, 'r') as f:
        prompt = yaml.safe_load(f)
    with open(dataset_file, 'r') as f:
        dataset = yaml.safe_load(f)

    # Validate the prompt and dataset files
    for attr in ["prompt", "model", "count", "base_id"]:
        if attr not in prompt:
            raise Exception(f"Prompt file {prompt_file} does not contain attribute '{attr}'")
    if "schema" not in dataset:
        raise Exception(f"Dataset file {dataset_file} does not contain attribute 'schema'")

    model = prompt["model"]
    temperature = prompt.get("temperature", 1.0)
    max_tokens = prompt.get("max_tokens", 1000)
    count = prompt["count"]
    base_id = prompt["base_id"]
    prompt_text = prompt["prompt"] + " " + dataset["schema"]

    def callback(id: str, sql: str):
        """
        Callback function to handle the answered requests.
        """
        write_query_to_file(sql, dest_dir, id)

    log.info(f"Using {model} model for generating {count} queries for {args.dataset} benchmark at version {args.version}")
    log.info(f"The generated queries will be saved in `{dest_dir}` in files `{base_id}.sql` to `{base_id + count - 1}.sql`")

    llm(model, count, base_id, prompt_text, callback, temperature=temperature, max_tokens=max_tokens, batch_output_file=args.batch_output_file)

    log.info(f"Generated {count} queries for {args.dataset} benchmark at version {args.version} using {model} model")
    log.info(f"The generated queries are saved in `{dest_dir}` in files `{base_id}.sql` to `{base_id + count - 1}.sql`")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.error(e)
        sys.exit(1)
