#!/usr/bin/env python3
import copy
import csv
import json
import sys
from dataclasses import dataclass, fields

import numpy as np
from util import smart_open

csv.field_size_limit(1024 * 1024)

input_columns = ["title", "query", "client_total_mean", "rows", "plan",
                 "error", "fatal", "oom", "timeout"]


def read_csv(csv_path):
    result = []

    # Open and read the CSV file
    with smart_open(csv_path, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)

        for row in reader:
            r = {}
            for col in input_columns:
                if col.startswith("extra."):
                    if row["extra"] == "null":
                        r[col] = 0
                    else:
                        r[col] = json.loads(row["extra"])[col[6:]]
                else:
                    r[col] = row[col]
            result.append(r)

    return result


@dataclass
class Operator:
    label: str
    estimated_cardinality: int
    exact_cardinality: int
    qerror: float
    operator_id: int
    depth: int
    children: list[int]


operators = ["Join", "GroupBy", "GroupJoin", "TableScan", "Select", "Iteration", "SetOperation", "RegexSplit"]

counter = -2


def analyze_plan(plan: dict, ops: dict):
    global counter

    label = plan["_label"]
    if "operator_id" not in plan["_attrs"]:
        plan["_attrs"]["operator_id"] = counter
        counter -= 1
    operator_id = plan["_attrs"]["operator_id"]
    estimated_cardinality = 0 if "estimated_cardinality" not in plan["_attrs"] else plan["_attrs"]["estimated_cardinality"]
    exact_cardinality = plan["_attrs"]["exact_cardinality"]
    qerror = max(estimated_cardinality, 1) / max(exact_cardinality, 1)  # > 1 if overestimation, < 1 if underestimation
    children = []
    depth = 0

    for child in plan["_children"]:
        if "operator_id" not in child["_attrs"]:
            child["_attrs"]["operator_id"] = counter
            counter -= 1
        child_id = child["_attrs"]["operator_id"]
        analyze_plan(child, ops)
        children.append(child_id)
        depth += ops[child_id].depth

    # Increment depth if operator is join, groupby, or groupjoin
    if label in operators and label != "TableScan":
        depth += 1

    ops[operator_id] = Operator(label, estimated_cardinality, exact_cardinality, qerror, operator_id, depth, children)


def main():
    # Get command line arguments
    if len(sys.argv) != 3:
        print("Usage: python script.py <source_csv> <dest_csv>")
        sys.exit(1)

    source_csv = sys.argv[1]
    dest_csv = sys.argv[2]

    data = read_csv(source_csv)
    result = []
    for d in data:
        r = {}
        r["system"] = d["title"]
        r["batch"] = 1
        try:
            r["batch"] = int((int(d["query"].split(".")[0]) + 4999) / 5000)
        except:
            pass
        r["query"] = d["query"]
        r["query_time"] = d["client_total_mean"]

        if d["plan"] == "" or (d["error"] != "") or (d["fatal"] == "True") or (d["oom"] == "True") or (d["timeout"] == "True"):
            continue

        plan = json.loads(d["plan"])
        ops = {}
        analyze_plan(plan["queryPlan"], ops)
        for op_id in sorted(ops.keys()):
            c = copy.deepcopy(r)
            op = ops[op_id]
            for k in fields(op):
                c[k.name] = getattr(op, k.name)
            result.append(c)

    analysis = {}
    queries = {}
    batches = [1, 2, 3, 4, 5, 6, 7]
    for batch in batches:
        analysis[batch] = {"depths": {}}
        queries[batch] = set()
        for op in operators:
            analysis[batch][op] = []

    for r in result:
        batch = r["batch"]
        depth = r["depth"]
        qerror = r["qerror"]
        label = r["label"]

        queries[batch].add(r["query"])

        if label in operators:
            analysis[batch][label].append(qerror)
            if depth not in analysis[batch]["depths"]:
                analysis[batch]["depths"][depth] = []
            analysis[batch]["depths"][depth].append(qerror)

    if False:
        for batch in batches:
            header = f"Batch {batch} - queries: {len(queries[batch])}, " + ", ".join([f"{k.lower()}: {len(analysis[batch][k])}" for k in operators])
            print(header)

            for k in operators:
                a = analysis[batch][k]
                if len(a) == 0:
                    continue

                median = round(np.median(a), 2)
                mean = round(np.mean(a), 2)
                max = round(np.max(a), 2)
                min = round(np.min(a), 2)
                print(f"\t{k}: min={min}, median={median}, mean={mean}, max={max}")

            for depth in sorted(analysis[batch]["depths"].keys()):
                a = analysis[batch]["depths"][depth]
                if len(a) == 0:
                    continue

                median = round(np.median(a), 2)
                mean = round(np.mean(a), 2)
                max = round(np.max(a), 2)
                min = round(np.min(a), 2)
                print(f"\t{depth}: min={min}, median={median}, mean={mean}, max={max}")

    # Write the result to the destination CSV file
    with smart_open(dest_csv, 'wt', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=r.keys())
        writer.writeheader()
        for r in result:
            writer.writerow(r)


if __name__ == "__main__":
    main()
