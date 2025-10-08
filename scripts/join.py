#!/usr/bin/env python3
import argparse
import csv
import os

import simplejson as json

from log import log
from util import smart_open

csv.field_size_limit(1024 * 1024)


def extract_ius(expression):
    s = set()
    if expression["expression"] == "iuref":
        s.add(expression["iu"])

    for k in ["values", "input"]:
        if k not in expression:
            continue

        if isinstance(expression[k], dict):
            s.update(extract_ius(expression[k]))
        elif isinstance(expression[k], list):
            for e in expression[k]:
                s.update(extract_ius(e))

    return s


def extract_iu(expression):
    if expression["expression"] == "iuref":
        return expression["iu"]
    elif expression["expression"] in ["cast", "lower", "upper"]:
        return extract_iu(expression["input"])
    elif expression["expression"] in ["coalesce"]:
        return extract_iu(expression["values"][0])
    elif expression["expression"] in ["concat", "stringconcat", "trimboth"]:
        iu = None
        for input in expression["input"]:
            i = extract_iu(input)
            if i is not None:
                if iu is not None:
                    return None
                iu = i
        return iu
    elif expression["expression"] in ["const", "div", "searchedcase", "round2", "add", "sub", "nullif", "arraylength", "simplecase", "charlength", "accesstext"]:
        return None
    else:
        log.print("extract_ui: ", expression)
        return None


def extract_equalities(expression):
    left = []
    right = []

    if expression["expression"] == "compare" and expression["direction"] in ["=", "is"]:
        left.append(extract_iu(expression["left"]))
        right.append(extract_iu(expression["right"]))
    elif expression["expression"] == "and":
        for input in expression["input"]:
            left_ius, right_ius = extract_equalities(input)
            left.extend(left_ius)
            right.extend(right_ius)
    elif expression["expression"] in ["like", "contains", "ilike"]:
        left.append(extract_iu(expression["input"][0]))
        right.append(extract_iu(expression["input"][1]))
    elif expression["expression"] in ["const", "or", "compare"]:
        return [], []
    else:
        log.print("extract_equalities: ", expression)

    return left, right


def extract_keys(keys, values):
    return [extract_iu(values[k["arg"]]) for k in keys]


def check_join(schema, left, right, ius_left, ius_right):
    for iu_left, iu_right in zip(left, right):
        if iu_left is None or iu_right is None:
            continue

        if iu_left in ius_right and iu_right in ius_left:
            temp = iu_left
            iu_left = iu_right
            iu_right = temp

        if iu_left in ius_left and iu_right in ius_right:
            column_left = ius_left[iu_left]
            column_right = ius_right[iu_right]

            assert column_left["table"] in schema and column_right["table"] in schema
            foreign_keys_left = schema[column_left["table"]]
            foreign_keys_right = schema[column_right["table"]]

            for fk in foreign_keys_left:
                if fk["column"] == column_left["column"] and fk["foreign table"] == column_right["table"] and fk["foreign column"] == column_right["column"]:
                    return True

            for fk in foreign_keys_right:
                if fk["column"] == column_right["column"] and fk["foreign table"] == column_left["table"] and fk["foreign column"] == column_left["column"]:
                    return True

    log.print(f"Join {left} {right} not a correct join edge")
    log.print(f"  Left: {[ius_left.get(l) for l in left]}")
    log.print(f"  Right: {[ius_right.get(r) for r in right]}")

    return False


def check_join_with_arrayunnest(left, right, ius_left, ius_right):
    if len(left) == 1 and len(right) == 1:
        iu_left = left[0]
        iu_right = right[0]

        if iu_left in ius_left and iu_right in ius_right:
            column_left = ius_left[iu_left]
            column_right = ius_right[iu_right]

            if column_left == column_right:
                return True

    log.print(f"ArrayUnnest Join {left} {right} not a correct join edge")
    return False


def map_groupby_keys(keys, values, ius, child_ius):
    for key in keys:
        expression = values[key["arg"]]
        if expression["expression"] == "iuref":
            if expression["iu"] in child_ius:
                ius[key["iu"]] = child_ius[expression["iu"]]


def map_groupby_aggregates(aggregates, values, ius, child_ius):
    for aggregate in aggregates:
        if aggregate["op"] in ["any"]:
            expression = values[aggregate["arg"]]
            if expression["expression"] == "iuref":
                if expression["iu"] in child_ius:
                    ius[aggregate["iu"]] = child_ius[expression["iu"]]


def load_system_representation(plan: dict):
    raw = json.loads(plan["_attrs"]["system_representation"])[0]
    raw["children"] = []
    for child in plan["_children"]:
        child_raw = load_system_representation(child)
        raw["children"].append(child_raw)
    return raw


def analyze_joins(plan: dict, schema: dict, ius: dict, plan_map: dict) -> bool:
    label = plan["_label"]
    raw = load_system_representation(plan)

    correct_join = True
    iu_list = []
    for child in plan["_children"]:
        child_ius = {}
        correct_join = correct_join and analyze_joins(child, schema, child_ius, plan_map)
        iu_list.append(child_ius)

    if label != "Result" and isinstance(raw, dict) and correct_join:

        match label:
            case "TableScan":
                for attribute in raw["attributes"]:
                    assert attribute["iu"] not in ius
                    ius[attribute["iu"]] = {"table": raw["tablename"], "column": attribute["name"], "operator_id": raw["operatorId"]}

            case "GroupBy":
                if not len(iu_list) == 1:
                    log.print(raw)
                assert len(iu_list) == 1

                map_groupby_keys(raw["key"], raw["values"], ius, iu_list[0])
                map_groupby_aggregates(raw["aggregates"], raw["values"], ius, iu_list[0])
                iu_list = []

            case "Join":
                assert len(iu_list) == 2
                correct_join = None

                if raw["physicalOperator"] in ["singletonjoin"]:
                    correct_join = True
                elif "condition" in raw:
                    expression = raw["condition"]
                    left, right = extract_equalities(expression)
                    correct_join = check_join(schema, left, right, iu_list[0], iu_list[1])

                    if not correct_join:
                        right_child = plan["_children"][1]
                        if right_child["_label"] == "Select":
                            right_child = right_child["_children"][0]
                        if right_child["_label"] == "ArrayUnnest":
                            correct_join = check_join_with_arrayunnest(left, right, iu_list[0], iu_list[1])

                if correct_join is None:
                    correct_join = False
                    log.print(raw)

            case "GroupJoin":
                assert len(iu_list) == 2
                correct_join = None

                if len(raw["keyLeft"]) == 1:
                    assert len(raw["keyRight"]) == 1

                    left = extract_keys(raw["keyLeft"], raw["valuesLeft"])
                    right = extract_keys(raw["keyRight"], raw["valuesRight"])
                    correct_join = check_join(schema, left, right, iu_list[0], iu_list[1])

                map_groupby_keys(raw["keyLeft"], raw["valuesLeft"], ius, iu_list[0])
                map_groupby_keys(raw["keyRight"], raw["valuesRight"], ius, iu_list[1])
                map_groupby_aggregates(raw["aggregatesLeft"], raw["valuesLeft"], ius, iu_list[0])
                map_groupby_aggregates(raw["aggregatesRight"], raw["valuesRight"], ius, iu_list[1])
                iu_list = []

                if correct_join is None:
                    correct_join = False
                    log.print(raw)

            case "PipelineBreakerScan":
                for o in raw["output"]:
                    if o["originalIU"] in iu_list[0]:
                        ius[o["iu"]] = iu_list[0][o["originalIU"]]
                iu_list = []

            case "Map":
                for v in raw["values"]:
                    iu = extract_iu(v["exp"])
                    if iu is not None and iu in iu_list[0]:
                        ius[v["iu"]] = iu_list[0][iu]

            case "IterationScan":
                child_ius = {}
                analyze_joins(plan_map[raw["iteration"]]["_children"][0], schema, child_ius, plan_map)

                iteration_raw = load_system_representation(plan_map[raw["iteration"]])
                for iu1, iu2 in zip(iteration_raw["leftColumns"], raw["output"]):
                    iu = extract_iu(iu1)
                    if iu in child_ius:
                        ius[iu2["iu"]] = child_ius[iu]

            case "Iteration":
                for iu1, iu2 in zip(raw["leftColumns"], raw["columns"]):
                    iu = extract_iu(iu1)
                    if iu in iu_list[0]:
                        ius[iu2["iu"]] = iu_list[0][iu]

            case "ArrayUnnest":
                exp_ius = extract_ius(raw["array"])
                if len(exp_ius) == 1:
                    iu = exp_ius.pop()
                    if iu in iu_list[0]:
                        ius[raw["iu"]] = iu_list[0][iu]

            case "RegexSplit":
                log.print(raw)

            case "Select" | "Sort" | "ArrayUnnest" | "Window" | "Temp" | "SetOperation" | "InlineTable":
                pass

            case _:
                log.print(label)
                log.print(raw)

    for l in iu_list:
        for iu in l.keys():
            assert iu not in ius
            ius[iu] = l[iu]

    return correct_join


def unfold_plan(current: dict, plan_map: dict):
    operator_id = current["_attrs"]["operator_id"]
    label = current["_label"]
    plan_map[operator_id] = current

    if label == "Join" and len(current["_children"]) == 3:
        magic = current["_children"][0]
        current["_children"] = current["_children"][1:]
        magic["_children"] = [current["_children"][0]]
        plan_map[magic["_attrs"]["operator_id"]] = magic

    for child in current["_children"]:
        unfold_plan(child, plan_map)

    if label == "PipelineBreakerScan" and len(current["_children"]) == 0:
        current["_children"].append(plan_map[current["_attrs"]["scanned_id"]])


def analyze_plan(plan: str, schema: dict):
    plan = json.loads(plan)["queryPlan"]
    plan_map = {}
    unfold_plan(plan, plan_map)
    return analyze_joins(plan, schema, {}, plan_map)


def analyze(csv_path: str, schema: dict):
    # Open and read the CSV file
    log.info("Loading the data...")
    num_queries = 0
    num_errors = 0
    correct_joins = []
    incorrect_joins = []
    with log.progress("Loading the data", total=0) as progress:
        with smart_open(csv_path, newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)

            for row in reader:
                num_queries += 1

                query = row['query']
                progress.description(query)

                if row["state"] != "success":
                    num_errors += (row["state"] != "success")
                    incorrect_joins.append(query)
                    progress.advance()
                    continue

                correct_join = analyze_plan(row["plan"], schema)
                log.print(f"{num_queries} {query} -> {correct_join}")

                if correct_join:
                    correct_joins.append(query)
                else:
                    incorrect_joins.append(query)

                progress.advance()

    log.info(f"Loaded {num_queries} queries with {num_errors} errors.")
    log.info(f"Found {len(correct_joins)} queries with correct joins.")
    log.info(f"Found {len(incorrect_joins)} queries with incorrect joins.")

    return correct_joins, incorrect_joins


def main():
    log.header("Compute distinct queries")

    # Get command line arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument("dataset", help="Dataset of the benchmark")
    argparser.add_argument("version", help="Version of the benchmark")
    argparser.add_argument("result", help="Result file")
    argparser.add_argument("--schema", default=None, help="Schema file")
    args = argparser.parse_args()

    schema_file = args.schema if args.schema else os.path.join("benchmark", "benchmarks", args.dataset, f"{args.dataset}.dbschema.json")
    if not os.path.exists(schema_file):
        raise FileNotFoundError(f"Schema file {schema_file} does not exist.")

    schema = {}
    log.info(f"Loading schema from {schema_file} ...")
    with open(schema_file, 'r', encoding='utf-8') as f:
        s = json.loads(f.read())
        for table in s["tables"]:
            name = table["name"].lower()
            schema[name] = table["foreign keys"] if "foreign keys" in table else []
            if "primary key" in table:
                schema[name].append({
                    "column": table["primary key"]["column"],
                    "foreign table": name,
                    "foreign column": table["primary key"]["column"]
                })

            for fk in schema[name]:
                fk["column"] = fk["column"].lower()
                fk["foreign table"] = fk["foreign table"].lower()
                fk["foreign column"] = fk["foreign column"].lower()

        if args.dataset == "stackoverflow":
            schema["users"].append({
                "column": "displayname",
                "foreign table": "users",
                "foreign column": "displayname"
            })
            schema["posts"].append({
                "column": "ownerdisplayname",
                "foreign table": "users",
                "foreign column": "displayname"
            })
            schema["posts"].append({
                "column": "lasteditordisplayname",
                "foreign table": "users",
                "foreign column": "displayname"
            })
            schema["comments"].append({
                "column": "userdisplayname",
                "foreign table": "users",
                "foreign column": "displayname"
            })
            schema["posthistory"].append({
                "column": "userdisplayname",
                "foreign table": "users",
                "foreign column": "displayname"
            })
            schema["posts"].append({
                "column": "tags",
                "foreign table": "tags",
                "foreign column": "tagname"
            })
            schema["posthistory"].append({
                "column": "comment",
                "foreign table": "closereasontypes",
                "foreign column": "id"
            })

        for t1 in schema.keys():
            new_foreign_keys = []
            for t2 in schema.keys():
                for fk1 in schema[t1]:
                    for fk2 in schema[t2]:
                        if fk1["foreign table"] == fk2["foreign table"] and fk1["foreign column"] == fk2["foreign column"]:
                            new_foreign_keys.append({
                                "column": fk1["column"],
                                "foreign table": t2,
                                "foreign column": fk2["column"]
                            })

            schema[t1].extend(new_foreign_keys)

    correct_joins, incorrect_joins = analyze(args.result, schema)

    correct_joins_csv = os.path.join(args.version, args.dataset, "correct_joins.csv")
    log.info(f"Writing queries with correct joins to {correct_joins_csv} ...")
    with log.progress("Writing distinct queries", total=len(correct_joins)) as progress:
        with smart_open(correct_joins_csv, 'wt', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["query"])
            writer.writeheader()

            for query in correct_joins:
                progress.description(query)
                writer.writerow({"query": query})
                progress.advance()

    incorrect_joins_csv = os.path.join(args.version, args.dataset, "incorrect_joins.csv")
    log.info(f"Writing queries with incorrect joins to {incorrect_joins_csv} ...")
    with log.progress("Writing distinct queries", total=len(incorrect_joins)) as progress:
        with smart_open(incorrect_joins_csv, 'wt', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["query"])
            writer.writeheader()

            for query in incorrect_joins:
                progress.description(query)
                writer.writerow({"query": query})
                progress.advance()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.error(e)
        raise e
