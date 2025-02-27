#!/usr/bin/env python3
import argparse
import glob
import json
import os
import random
import re
import shutil
import subprocess

import duckdb

from log import log


def generate_templates(schema, query_orig_dir):
    templates = {}
    for query_file in glob.glob(f"{query_orig_dir}/*.sql"):
        template_name = int(os.path.basename(query_file)[:-5])
        if template_name in templates:
            templates[template_name]["count"] += 1
            continue

        # Read the query
        with open(query_file) as f:
            q = f.read().strip().strip(";")

        # Find the SELECT, FROM, and WHERE clauses
        select_pos = q.find("SELECT")
        from_pos = q.find("FROM")
        where_pos = q.find("WHERE")

        select_part = q[select_pos + 6:from_pos].split(",")
        from_part = q[from_pos + 4:where_pos].split(",")
        where_part = re.split(r'\band\b', q[where_pos + 5:], flags=re.IGNORECASE)

        def split_select(x):
            # parse min(a) as b to [a, b]
            if "AS" in x:
                parts = [c.strip() for c in x.strip().split("AS")]
            else:
                parts = [c.strip() for c in x.strip().split(" ")]
            parts[0] = parts[0][4:-1]
            return parts

        select_part = [split_select(x) for x in select_part]

        def split_from(x):
            if "AS" in x:
                res = [c.strip() for c in x.strip().split("AS")]
            else:
                res = [c.strip() for c in x.strip().split(" ")]
            return {"table": res[0], "alias": res[1]}

        from_part = [split_from(x) for x in from_part]

        joinPredicates = []
        for p in where_part:
            p = p.strip()
            porg = p
            # if predicate looks like "a.b = c.d" not "a.b = 1"
            if "=" not in p:
                continue
            p = p.split("=")
            if len(p) != 2:
                continue
            if "." not in p[0] or "." not in p[1]:
                continue
            joinPredicates.append(porg)

        columns = []
        aliases = {}
        for ff in from_part:
            tbl = ff["table"]
            alias = ff["alias"]
            aliases[alias] = tbl
            t = schema[tbl]
            for c, v in t.items():
                columns.append({"alias": f"{alias}.{c}", "table": tbl, "column": c})

        sels = []
        for n, r in select_part:
            a, c = [v.strip() for v in n.split(".")]
            sels.append({"attr": n, "table": aliases[a], "alias": a, "column": c, "rename": r})

        res = {
            "select": sels,
            "from": from_part,
            "join": joinPredicates,
            "columns": columns,
            "count": 1,
        }

        templates[template_name] = res

    return templates


def prepare_duckdb(schema: dict) -> duckdb.DuckDBPyConnection:
    """
    Prepare the DuckDB connection and create the tables.
    """
    log.info("Downloading DuckDB ...")
    try:
        if os.path.exists("/tmp/duckdb"):
            os.remove("/tmp/duckdb")
        if os.path.exists("/tmp/duckdb.zip"):
            os.remove("/tmp/duckdb.zip")

        args = ["wget", "https://github.com/duckdb/duckdb/releases/download/v1.2.0/duckdb_cli-linux-amd64.zip", "-O", "/tmp/duckdb.zip"]
        result = subprocess.run(args, capture_output=True, text=True, start_new_session=True)
        if result.returncode != 0:
            raise Exception(f"Failed to download DuckDB: {result.stderr} (return code {result.returncode})")

        args = ["unzip", "/tmp/duckdb.zip", "-d", "/tmp"]
        result = subprocess.run(args, capture_output=True, text=True, start_new_session=True)
        if result.returncode != 0:
            raise Exception(f"Failed to unzip DuckDB: {result.stderr} (return code {result.returncode})")

    except Exception as e:
        raise Exception(f"Failed to download DuckDB: {e}")

    log.info("Preparing DuckDB database ...")
    if os.path.exists("/tmp/imdb.db"):
        os.remove("/tmp/imdb.db")

    conn = duckdb.connect(database='/tmp/imdb.db')

    # Create tables
    log.info(f"Creating {len(schema.keys())} tables")
    with log.progress("Creating tables ...", total=len(schema.keys())) as progress:
        for table, columns in schema.items():
            progress.description(f"Creating table {table}")
            column_defs = []
            for col, v in columns.items():
                if v["type"] == "text":
                    column_defs.append(f"{col} TEXT")
                elif v["type"] == "integer":
                    column_defs.append(f"{col} INTEGER")
                else:
                    raise Exception(f"Unknown type {v['type']} for column {col} in table {table}")
                if v["not_null"]:
                    column_defs[-1] += " NOT NULL"

            log.info_verbose(f"CREATE TABLE {table} ({', '.join(column_defs)})")
            conn.execute(f"CREATE TABLE {table} ({', '.join(column_defs)});")
            progress.advance()

    # Load the data
    log.info(f"Loading data for {len(schema.keys())} tables")
    with log.progress("Loading data ...", total=len(schema.keys())) as progress:
        for table in schema.keys():
            progress.description(f"{table}")
            if not os.path.exists(f"data/job/{table}.csv"):
                raise Exception(f"Data file data/job/{table}.csv does not exist.")

            log.info_verbose(f"COPY {table} FROM 'data/job/{table}.csv' (ESCAPE '\"')")
            conn.execute(f"COPY {table} FROM 'data/job/{table}.csv' (ESCAPE '\"');")
            progress.advance()

    return conn


def prepare_domains(schema: dict, conn: duckdb.DuckDBPyConnection):
    columns = [(table, col) for table in schema.keys() for col in schema[table].keys()]
    log.info(f"Computing domains for {len(columns)} columns")
    with log.progress("Computing domains ...", total=len(columns)) as progress:
        for i, (table, column) in enumerate(columns):
            progress.description(f"{table}.{column}")

            res = conn.execute(f"SELECT DISTINCT {column} FROM {table} WHERE {column} IS NOT NULL ORDER BY {column}")
            domain = [r[0] for r in res.fetchall()]

            if len(domain) > 0 and isinstance(domain[0], str):
                domain = [d for d in domain if d is None or "'" not in d]

            schema[table][column]["domain"] = domain
            progress.advance()

    return schema


def format_constant(const):
    if const is None:
        return "NULL"
    if isinstance(const, str):
        return f"'{const}'"
    return str(const)


def pick_constant(schema, table, column):
    domain = schema[table][column]["domain"]
    if len(domain) == 0:
        return None
    return format_constant(random.choice(domain))


def pick_constant_for_like(schema, table, column):
    domain = schema[table][column]["domain"]
    if len(domain) == 0:
        return None
    const = random.choice(domain)
    if const is None:
        return format_constant(const)

    def format_result(const):
        return f"'%{const}%'"

    if "-" in const:
        return format_result(random.choice(const.split("-")))
    if " " in const:
        return format_result(random.choice(const.split(" ")))
    # random substring
    r0 = random.randint(0, len(const) - 1)
    r1 = random.randint(r0 + 1, len(const))
    return format_result(const[r0:r1])


def gen_eq(schema, name, table, column):
    c = pick_constant(schema, table, column)
    if c is None:
        return None
    return f"{name} = {c}"


def gen_lt(schema, name, table, column):
    c = pick_constant(schema, table, column)
    if c is None:
        return None
    return f"{name} < {c}"


def gen_gt(schema, name, table, column):
    c = pick_constant(schema, table, column)
    if c is None:
        return None
    return f"{name} > {c}"


def gen_between(schema, name, table, column):
    c1 = pick_constant(schema, table, column)
    c2 = pick_constant(schema, table, column)
    if c1 is None or c2 is None:
        return None
    if c1 > c2:
        c1, c2 = c2, c1
    return f"{name} BETWEEN {c1} AND {c2}"


def gen_in(schema, name, table, column):
    domain = schema[table][column]["domain"]
    if len(domain) == 0:
        return None
    numValues = random.randint(1, min(10, len(domain)))
    values = [format_constant(v) for v in random.sample(domain, numValues)]
    values.sort()
    return f"{name} IN ({', '.join(values)})"


def gen_like(schema, name, table, column):
    c = pick_constant_for_like(schema, table, column)
    if c is None:
        return None
    return f"{name} LIKE {c}"


def gen_is_not_null(schema, name, table, column):
    if schema[table][column]["not_null"]:
        return None
    return f"{name} IS NOT NULL"


gens = {
    "text": [gen_eq, gen_lt, gen_gt, gen_in, gen_is_not_null, gen_like],
    "integer": [gen_eq, gen_lt, gen_gt, gen_is_not_null, gen_in]
}


def gen_predicate(schema, name, table, column):
    type = schema[table][column]["type"]
    return random.choice(gens[type])(schema, name, table, column)


def gen_predicates(schema, template):
    predicates = []
    numPredicates = random.randint(0, min(8, len(template["columns"])))
    for col in random.sample(template["columns"], numPredicates):
        p = gen_predicate(schema, col["alias"], col["table"], col["column"])
        if p is not None:
            predicates.append(p)
    return " AND ".join(predicates)


def query_to_str(template, predicates=None, count_star=False):
    query = ""
    query += "SELECT "
    if count_star:
        query += "COUNT(*) AS count"
    else:
        query += ", ".join([f"min({s['attr']}) AS {s['rename']}" for s in template["select"]])
    query += "\nFROM "
    query += ", ".join([f"{f['table']} AS {f['alias']}" for f in template["from"]])
    query += "\nWHERE "
    query += " AND ".join(template["join"])
    if predicates is not None and len(predicates) > 0:
        query += "\nAND "
        query += predicates
    query += ";"
    return query


def gen_query(schema, template):
    preds = gen_predicates(schema, template)
    return query_to_str(template, preds, count_star=False), query_to_str(template, preds, count_star=True)


def test_in_duckdb(query):
    try:
        args = ["/tmp/duckdb", "/tmp/imdb.db", "-csv", "-c", f"set memory_limit='10GB'; set temp_directory='';{query}"]
        result = subprocess.run(args, capture_output=True, text=True, timeout=10, start_new_session=True)

        # Check if DuckDB returned an error or was killed.
        if result.returncode != 0:
            # do not print oom as we expect it
            if "Out of Memory Error" not in result.stderr:
                log.error(f"DuckDB shell process failed: `{result.stderr}` (return code {result.returncode})")
            return False

        last = [l for l in result.stdout.split("\n") if l.strip() != ""][-1]
        log.info_verbose(f"DuckDB shell process output: `{last}`")
        return 0 < int(last) < 1e9

    except subprocess.TimeoutExpired:
        log.error("DuckDB shell process timed out.")
        return False

    except Exception as e:
        log.error(f"DuckDB shell process failed: {e}")
        return False


def main():
    """
    Main function to generate queries for the JOB benchmark.
    """
    log.header("JOB Query Generator")

    # Parse command line arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument("dataset", help="Dataset of the benchmark")
    argparser.add_argument("version", help="Version of the benchmark")
    argparser.add_argument("--seed", type=int, default=42, help="Random seed for query generation")
    argparser.add_argument("--count", type=int, default=1, help="Number of queries to generate per template")
    args = argparser.parse_args()

    random.seed(args.seed)

    query_dest_dir = os.path.join(args.version, args.dataset, "queries")
    query_orig_dir = os.path.join(args.version, args.dataset, "queries_original")
    job_schema_file = os.path.join(args.version, args.dataset, "schema.json")

    if not os.path.exists(job_schema_file):
        raise Exception(f"Schema file {job_schema_file} does not exist.")
    if not os.path.exists(query_orig_dir):
        raise Exception(f"Original query directory {query_orig_dir} does not exist.")

    # Remove all files in the destination directory
    if os.path.exists(query_dest_dir):
        shutil.rmtree(query_dest_dir)
    os.makedirs(query_dest_dir)

    with open(job_schema_file) as f:
        schema = json.load(f)

    conn = prepare_duckdb(schema)
    schema = prepare_domains(schema, conn)
    templates = generate_templates(schema, query_orig_dir)
    conn.close()

    count = args.count
    template_count = sum([t["count"] for t in templates.values()])
    with log.progress("Generating queries", total=count * template_count) as progress:
        for i in range(count * len(templates)):
            template = templates[(i % len(templates)) + 1]

            for j in range(template["count"]):
                name = f"{i + 1}{'abcdefghijklmnopqrstuvwxyz'[j]}.sql"
                progress.description(f"{name}")

                attempts = 1
                if i < len(templates):
                    # Copy the existing job queries
                    with open(os.path.join(query_orig_dir, name)) as f:
                        q = f.read()

                else:
                    # Generate a new query
                    while True:
                        q, q_star = gen_query(schema, template)
                        if test_in_duckdb(q_star):
                            break
                        attempts += 1

                with open(os.path.join(query_dest_dir, name), "w") as f:
                    f.write(q)

                log.info(f"Genserated {name} after {attempts} attempts")
                progress.advance()

    log.info(f"Generated {count * template_count} queries in {query_dest_dir}.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.error(e)
        raise e
