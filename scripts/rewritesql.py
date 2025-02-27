#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
import time
from tempfile import TemporaryDirectory

from openai import OpenAI


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


prompts = {
    "sqlserver": "Convert the following PostgreSQL query to T-SQL syntax. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query",
    "mysql": "Convert the following PostgreSQL query to MySQL syntax. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query",
    "fix": "Make the following PostgreSQL query more compatible with different SQL dialects. The query might contain \'::\' casts, rewrite them to standard SQL. The query might contain some errors, fix them if you can find any mistakes. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query",
    "compatible": "Make the following PostgreSQL query more compatible with different SQL dialects. The query might contain \'::\' casts, rewrite them to standard SQL. Remember to put all ungrouped columns and columns that appear in windows into the group by clause. Do not explain the query, only output the converted query",
    "deterministic": "Make the following SQL query deterministic. In \'string_agg\' functions order by the argument and in \'order by\' clauses add all columns that are in the select clause. Do not explain the query, only output the converted query",
    "incompatible": None
}

batch_head = '{"custom_id": "'
batch_body = '", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-4o-mini", "temperature": 1.0, "max_tokens": 1000, "messages": [{"role": "system", "content": "You are a SQL generator that cannot speak."},{"role": "user", "content": "'
batch_tail = '"}]}}\n'


def escape_backslash(s: str) -> str:
    # Replace all single backslashes with double backslashes
    return re.sub(r'(?<!\\)\\(?!\\)', r'\\\\', s)


def rewrite_queries(src_dir: str, dst_dir: str, prompt: str, offset: int, limit: int, realtime: bool = False, copy_only: bool = False):
    # Check if destination directory exists, create if it doesn't
    if not os.path.exists(dst_dir):
        os.makedirs(dst_dir)

    # Iterate over files in the source directory
    count = 0
    queries = []
    for filename in os.listdir(src_dir):
        src_file_path = os.path.join(src_dir, filename)

        # Only copy files with <int>.sql, skip directories
        if filename.endswith('.sql') and filename.split('.')[0].isdigit() and os.path.isfile(src_file_path):
            id = int(filename.split('.')[0])
            with open(src_file_path, 'r') as f:
                sql = f.read()
                query = escape_backslash(sql).replace('\n', '\\n').replace('"', '\\"')
                queries.append((id, query, sql))

            count += 1

    # Sort queries by id ascending
    queries.sort(key=lambda x: x[0])
    queries = queries[offset:offset + limit]

    print("first id: ", queries[0][0], ", last id: ", queries[-1][0], " count: ", len(queries))

    if copy_only:
        for (id, _, query) in queries:
            write_query_to_file(query, dst_dir, id)

    elif not realtime:
        assert prompt is not None

        tempdir = TemporaryDirectory()
        input_file = os.path.join(tempdir.name, "input.jsonl")

        with open(input_file, 'w') as f:
            for (id, query, _) in queries:
                f.write(batch_head)
                f.write(str(id))
                f.write(batch_body)

                f.write(prompt)
                f.write(" ```")
                f.write(query)
                f.write("```")

                f.write(batch_tail)

        client = OpenAI()
        batch_input_file = client.files.create(file=open(input_file, "rb"), purpose="batch")

        batch = client.batches.create(input_file_id=batch_input_file.id, endpoint="/v1/chat/completions", completion_window="24h", metadata={"description": "1k"})
        print("BatchId: ", batch.id)
        time.sleep(10)

        result = client.batches.retrieve(batch.id)
        while (result.status != 'completed'):
            if (result.status == 'failed'):
                eprint(result)
                exit(1)
            time.sleep(30)
            result = client.batches.retrieve(batch.id)

        file_response = client.files.content(result.output_file_id)
        print(file_response.text)

        text = file_response.text.split('\n')
        print_queries(text, dst_dir)

        # client.files.delete(result.output_file_id)
        # client.files.delete(batch_input_file.id)

    else:
        assert prompt is not None

        client = OpenAI()
        for (id, query, _) in queries:
            completion = client.chat.completions.create(model="gpt-4o-mini",
                                                        messages=[{"role": "system", "content": "You are a SQL generator that cannot speak."},
                                                                  {"role": "user", "content": prompt + " ```" + query + "```"}])
            sql = completion.choices[0].message.content
            write_query_to_file(sql, dst_dir, id)


def write_query_to_file(sql: str, dst_dir: str, id: int):
    if sql.startswith("```"):
        sql = sql.removeprefix("```").removesuffix("```")
    if sql.startswith("sql"):
        sql = sql.removeprefix("sql")
    if sql.startswith("\\n"):
        sql = sql.removeprefix("\\n")

    with open(os.path.join(dst_dir, f"{id}.sql"), 'w') as f:
        f.write(sql)


def print_queries(lines: list[str], dst_dir: str):
    for i in range(len(lines)):
        if lines[i] == "":
            continue
        print(f"{i}: ```{lines[i]}```")
        response = json.loads(lines[i])
        sql = response["response"]["body"]["choices"][0]["message"]["content"]
        id = response["custom_id"]

        write_query_to_file(sql, dst_dir, id)


def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument("query_source_dir", help="Directory containing queries to rewrite")
    argparser.add_argument("dialect", help="Dialect to rewrite queries to")
    argparser.add_argument("-b", "--batch_file", help="Directory containing queries to rewrite")
    argparser.add_argument("-o", "--offset", help="Offset of queries to rewrite")
    argparser.add_argument("-l", "--limit", help="Number of queries to rewrite")
    argparser.add_argument("--realtime", help="Use the realtime api", action="store_true")
    argparser.add_argument("--copy", help="Only copy queries", action="store_true")

    args = argparser.parse_args()
    query_source_dir = args.query_source_dir
    dialect = args.dialect

    if dialect not in prompts.keys():
        eprint(f"Unknown dialect: {dialect}")
        eprint("Supported dialects: " + ", ".join(prompts.keys()))
        sys.exit(1)

    query_dest_dir = query_source_dir + "_" + dialect

    # parse the batch file
    if args.batch_file:
        with open(args.batch_file, 'r') as f:
            lines = f.readlines()
            print_queries(lines, query_dest_dir)
        return

    assert (args.offset and args.limit)
    offset = int(args.offset)
    limit = int(args.limit)

    realtime = args.realtime
    copy_only = args.copy

    print(f"Rewriting queries from {query_source_dir} to {query_dest_dir} for dialect {dialect}")
    rewrite_queries(query_source_dir, query_dest_dir, prompts[dialect], offset, limit, realtime=realtime, copy_only=copy_only)


if __name__ == "__main__":
    main()
