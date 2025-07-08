#!/usr/bin/env python3
import argparse
import csv
import os
import re
import sys

from llm import llm
from log import Log
from prompt import write_query_to_file


log = Log()


prompts = {
    "sqlserver": "Convert the following PostgreSQL query to T-SQL syntax. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query.",
    "mysql": "Convert the following PostgreSQL query to MySQL syntax. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query.",
    "snowflake": "Convert the following PostgreSQL query to Snowflake's SQL syntax. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query.",
    "fix": "Make the following PostgreSQL query more compatible with different SQL dialects. The query might contain \'::\' casts, rewrite them to standard SQL. The query might contain some errors, fix them if you can find any mistakes. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query.",
    "compatible": "Make the following PostgreSQL query more compatible with different SQL dialects. The query might contain \'::\' casts, rewrite them to standard SQL. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query.",
    "deterministic": "Make the following SQL query deterministic. In \'string_agg\' functions order by the argument and in \'order by\' clauses add all columns that are in the select clause. Do not explain the query, only output the converted query.",
    "incompatible": None
}


def escape_backslash(s: str) -> str:
    # Replace all single backslashes with double backslashes
    return re.sub(r'(?<!\\)\\(?!\\)', r'\\\\', s)


def rewrite_queries(src_dir: str, dst_dir: str, prompt: str, offset: int, limit: int, results_path: str = None, batch_output_file: str = None):
    # Check if destination directory exists, create if it doesn't
    if not os.path.exists(dst_dir):
        os.makedirs(dst_dir)

    # Iterate over files in the source directory
    count = 0
    queries = []
    with log.progress("Reading queries from source directory", total=len(os.listdir(src_dir))) as progress:
        for filename in os.listdir(src_dir):
            progress.description(filename)
            src_file_path = os.path.join(src_dir, filename)

            # Only copy files with <int>.sql, skip directories
            if filename.endswith('.sql') and filename.split('.')[0].isdigit() and os.path.isfile(src_file_path):
                id = int(filename.split('.')[0])
                with open(src_file_path, 'r') as f:
                    sql = f.read()
                    queries.append((id, sql))

                count += 1

            progress.advance()

    # Sort queries by id ascending
    queries.sort(key=lambda x: x[0])
    queries = queries[offset:offset + limit]

    failed_queries = {}
    if results_path is not None:
        log.info(f"Loading results from `{results_path}` to find failed queries")
        with log.progress("Loading the data", total=0) as progress:
            with open(results_path, newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)

                for row in reader:
                    id = int(row['query'].split('.')[0])
                    progress.description(f"{id}.sql")

                    if row["state"] != "success":
                        failed_queries[id] = row["message"]
                    progress.advance()
    else:
        for (id, _) in queries:
            failed_queries[id] = None

    log.info(f"Found {len(queries)} queries, {len(failed_queries)} of them failed")
    log.info("Copying successful queries to destination directory")
    copied_queries = 0
    for (id, sql) in queries:
        if id not in failed_queries:
            write_query_to_file(sql, dst_dir, id)
            copied_queries += 1

    queries = [(id, sql) for (id, sql) in queries if id in failed_queries]

    assert prompt is not None

    prompts = [f"{prompt}\n```{sql}```" + (f"\n\nThe following error occured:\n{failed_queries[id]}" if failed_queries[id] is not None else "") for (id, sql) in queries]
    ids = [str(id) for (id, _) in queries]

    def callback(id: str, sql: str):
        write_query_to_file(sql, dst_dir, id)

    model = "gpt-4o-mini"
    count = len(prompts)
    log.info(f"Using {model} model for rewriting {count} queries")
    llm(model, count, ids, prompts, callback, batch_output_file=batch_output_file)

    log.info(f"Rewrote {count} failed queries and copied {copied_queries} successful queries to `{dst_dir}`")


def main():
    log.header("Rewrite SQL Queries")

    argparser = argparse.ArgumentParser()
    argparser.add_argument("dataset", help="Dataset of the benchmark")
    argparser.add_argument("version", help="Version of the benchmark")
    argparser.add_argument("dialect", help="Dialect to rewrite queries to")
    argparser.add_argument("-r", "--results", default=None, help="Benchmark results, rewritten only queries that are not executable")
    argparser.add_argument("-b", "--batch_file", default=None, help="Directory containing queries to rewrite")
    argparser.add_argument("-o", "--offset", default=0, help="Offset of queries to rewrite")
    argparser.add_argument("-l", "--limit", default=sys.maxsize, help="Number of queries to rewrite")
    args = argparser.parse_args()

    query_source_dir = os.path.join(args.version, args.dataset, "queries")
    if not os.path.exists(query_source_dir):
        raise FileNotFoundError(f"Query source directory {query_source_dir} does not exist")

    dialect = args.dialect
    if dialect not in prompts.keys():
        raise ValueError(f"Unknown dialect: {dialect}, supported dialects: {', '.join(prompts.keys())}")

    query_dest_dir = query_source_dir + "_" + dialect

    offset = int(args.offset)
    limit = int(args.limit)

    log.info(f"Rewriting queries from {query_source_dir} to {query_dest_dir} for dialect {dialect}")
    rewrite_queries(query_source_dir, query_dest_dir, prompts[dialect], offset, limit, results_path=args.results, batch_output_file=args.batch_file)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.error(e)
        raise e
