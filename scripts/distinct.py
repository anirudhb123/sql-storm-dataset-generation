#!/usr/bin/env python3
import argparse
from collections import deque
import copy
import csv
import os
from dataclasses import dataclass

import simplejson as json

from log import log
from util import smart_open

csv.field_size_limit(1024 * 1024)


@dataclass
class Expression:
    label: str
    type: str
    attributes: str = ""

    def __eq__(self, other):
        if not isinstance(other, Expression):
            return False
        return (self.label == other.label and
                self.type == other.type and
                self.attributes == other.attributes)

    def __hash__(self):
        return hash((self.label, self.type, self.attributes))


@dataclass
class Operator:
    label: str
    attributes: str
    expressions: set[Expression]
    expression_list: list[Expression]
    children: list[int]

    def __hash__(self):
        return hash((self.label, self.attributes, frozenset(self.expressions)))

    def __eq__(self, other):
        if not isinstance(other, Operator):
            return False
        return (self.label == other.label and
                self.attributes == other.attributes and
                self.expressions == other.expressions and
                self.children == other.children)


@dataclass
class Result:
    query: str
    attributes: dict
    distinct_trees: int
    distinct_operators: int
    tree: dict[int, Operator]


def analyze_expression(plan: dict, expressions: list[Expression]):
    if isinstance(plan, list):
        for p in plan:
            analyze_expression(p, expressions)
    elif isinstance(plan, dict):
        for _, p in plan.items():
            analyze_expression(p, expressions)

        if "restrictions" in plan:
            for restriction in plan["restrictions"]:
                mode = restriction["mode"]
                if mode in ["=", "!=", "is", "isnot", "<", "<=", ">", ">="]:
                    label = "compare"
                elif mode in ["[]", "(]", "[)", "()"]:
                    label = "between"
                elif mode in ["isnull"]:
                    label = "isnull"
                elif mode in ["isnotnull"]:
                    label = "isnotnull"
                elif mode in ["false"]:
                    label = "false"
                else:
                    raise Exception(f"Unknown restriction mode: {mode}")

                restriction_type = "unknown"
                if "value" in restriction:
                    if "_type" in restriction["value"]:
                        restriction_type = restriction["value"]["_type"]

                expressions.append(Expression(label, restriction_type))

        if "expression" in plan:
            label = plan["expression"]
            if "_type" not in plan:
                log.print(label)
                log.print(plan)

            attributes = label
            if "input" in plan and isinstance(plan["input"], list):
                attributes += "|" + str(len(plan["input"]))
            if "values" in plan and isinstance(plan["values"], list):
                attributes += "|" + str(len(plan["values"]))

            match label:
                case "cast":
                    attributes += "|" + plan["semantic"]
                case "compare" | "quantified":
                    attributes += "|" + plan["direction"]
                case "simplecase" | "searchedcase":
                    attributes += "|" + str(len(plan["cases"]))
                case "greatestleast":
                    attributes += "|" + plan["mode"]
                case "datetrunc" | "datepart":
                    if plan["input"][0]["expression"] == "const":
                        attributes += "|" + plan["input"][0]["value"]["value"]
                case "mul" | "div" | "rem" | "add" | "sub" | "abs" | "round" | "round2" | "neg" | "random" | "ceil" | "floor" | "cos" | "trunc" \
                     | "and" | "or" | "not" | "bitand" | "bitor" | "shiftright" | "shiftleft" \
                     | "iuref" | "const" | "nullif" | "nullifnottrue" | "trueornull" | "coalesce" | "error" \
                     | "concat" | "concat_ws" | "stringconcat" \
                     | "substring" | "replace" | "lpad" | "upper" | "lower" | "trimboth" | "trimleading" | "trimtrailing" | "charlength" | "position" | "split_part" | "translate" | "left" | "right" | "initcap" | "repeat" | "reverse" | "md5" \
                     | "regexp_replace" | "regexp_split_to_array" | "regexp_substr" \
                     | "arraylength" | "stringToArray" | "arrayToString" | "cardinality" | "arraybuild" | "arrayappend" | "arrayremove" | "arrayaccess" | "arrayoverlap" | "arrayslice" \
                     | "like" | "ilike" | "startswith" | "contains" \
                     | "in" | "between" | "isnotnull" | "isnull" \
                     | "accesstext" \
                     | "age" | "extractepoch" | "extractyear" | "extractmonth" | "extractweek" | "extractday" | "extractdoy" | "extracthour" | "extractquarter" | "extractminute" | "extractsecond" | "extractdow" | "to_timestamp":
                    pass
                case _:
                    log.print(label)
                    log.print(plan)

            expressions.append(Expression(label, plan["_type"], attributes))


def analyze_operator(plan: dict, operators: dict[int, Operator], ius=None):
    if ius is None:
        ius = {}

    label = plan["_label"]
    operator_id = plan["_attrs"]["operator_id"]
    system_representation = json.loads(plan["_attrs"]["system_representation"])

    attributes = ""
    children = []
    expressions = []

    raw = system_representation[0]
    if label == "Result":
        for iu in raw.get("ius", []):
            iu_type = iu.get("type", {})
            precision = iu_type.get("precision")
            scale = iu_type.get("scale")
            type_name = iu_type.get("type", "unknown")
            if precision is not None and scale is not None:
                ius[iu["iu"]] = f"{type_name}({precision},{scale})"
            elif precision is not None:
                ius[iu["iu"]] = f"{type_name}({precision})"
            else:
                ius[iu["iu"]] = type_name

    for child in plan.get("_children", []):
        child_id = child["_attrs"]["operator_id"]
        analyze_operator(child, operators, ius)
        children.append(child_id)

    if label != "Result" and isinstance(raw, dict):
        attributes = raw["physicalOperator"]
        match label:
            case "TableScan":
                attributes += "|" + raw["tablename"]
                attributes += "|ius" + str(len(raw["_ius"]))
                attributes += "|filters" + str(len(raw["residuals"]) + len(raw["restrictions"]))
                for iu in raw["_ius"]:
                    expressions.append(Expression("iu", ius[iu], "iu"))

            case "GroupBy":
                attributes += "|" + raw["groupingmode"]
                if len(raw["key"]) > 0:
                    attributes += "|key" + str(len(raw["key"]))
                if len(raw["aggregates"]) > 0:
                    attributes += "|aggregates" + str(len(raw["aggregates"]))
                if len(raw["orders"]) > 0:
                    attributes += "|orders" + str(len(raw["orders"]))
                if len(raw["groupingsets"]) > 0:
                    attributes += "|groupingsets" + str(len(raw["groupingsets"]))
                for i, key in enumerate(raw["key"]):
                    keylabel = "key_" + str(i)
                    keytype = raw["values"][key["arg"]]["_type"]
                    expressions.append(Expression(keylabel, keytype, keylabel))
                for aggregate in raw["aggregates"]:
                    agglabel = "agg_" + aggregate["op"]
                    aggtype = ius[aggregate["iu"]]
                    expressions.append(Expression(agglabel, aggtype, agglabel))

            case "Join":
                attributes += "|" + raw["type"]
                if "magic" in raw:
                    attributes += "|magic"
                left = json.loads(plan["_children"][0]["_attrs"]["system_representation"])[0]
                attributes += "|entries" + str(len(left["_ius"]))
                for iu in left["_ius"]:
                    expressions.append(Expression("entry", ius[iu], "entry"))

            case "GroupJoin":
                attributes += "|" + raw["behavior"]
                if len(raw["keyLeft"]) > 0:
                    attributes += "|keyLeft" + str(len(raw["keyLeft"]))
                if len(raw["keyRight"]) > 0:
                    attributes += "|keyRight" + str(len(raw["keyRight"]))
                if len(raw["aggregatesLeft"]) > 0:
                    attributes += "|aggregates" + str(len(raw["aggregatesLeft"]))
                if len(raw["aggregatesRight"]) > 0:
                    attributes += "|aggregatesRight" + str(len(raw["aggregatesRight"]))
                if len(raw["ordersLeft"]) > 0:
                    attributes += "|ordersLeft" + str(len(raw["ordersLeft"]))
                if len(raw["ordersRight"]) > 0:
                    attributes += "|ordersRight" + str(len(raw["ordersRight"]))
                for i, key in enumerate(raw["keyLeft"]):
                    keylabel = "keyLeft_" + str(i)
                    keytype = raw["valuesLeft"][key["arg"]]["_type"]
                    expressions.append(Expression(keylabel, keytype, keylabel))
                for i, key in enumerate(raw["keyRight"]):
                    keylabel = "keyRight_" + str(i)
                    keytype = raw["valuesRight"][key["arg"]]["_type"]
                    expressions.append(Expression(keylabel, keytype, keylabel))
                for aggregate in raw["aggregatesLeft"]:
                    agglabel = "aggLeft_" + aggregate["op"]
                    aggtype = ius[aggregate["iu"]]
                    expressions.append(Expression(agglabel, aggtype, agglabel))

                for aggregate in raw["aggregatesRight"]:
                    agglabel = "aggRight_" + aggregate["op"]
                    aggtype = ius[aggregate["iu"]]
                    expressions.append(Expression(agglabel, aggtype, agglabel))

            case "PipelineBreakerScan":
                if len(plan["_children"]) == 0:
                    children.append(raw["scannedOperator"])

                attributes += "|ius" + str(len(raw["_ius"]))
                for iu in raw["_ius"]:
                    expressions.append(Expression("iu", ius[iu], "iu"))

            case "Sort":
                attributes += "|order" + str(len(raw["order"]))
                if "orderGroups" in raw and len(raw["orderGroups"]) > 0:
                    attributes += "|orderGroups" + str(len(raw["orderGroups"]))
                if "limit" in raw:
                    attributes += "|limit"
                if "offset" in raw:
                    attributes += "|offset"
                if "distinct" in raw:
                    attributes += "|distinct"
                if "withTies" in raw:
                    attributes += "|withTies"

                attributes += "|ius" + str(len(raw["_ius"]))
                for iu in raw["_ius"]:
                    expressions.append(Expression("iu", ius[iu], "iu"))

            case "Map":
                attributes += "|values" + str(len(raw["values"]))
                for value in raw["values"]:
                    expressions.append(Expression("value", ius[value["iu"]], "value"))

            case "SetOperation":
                attributes += "|" + raw["operation"]
                attributes += "|ius" + str(len(raw["_ius"]))
                for iu in raw["_ius"]:
                    expressions.append(Expression("iu", ius[iu], "iu"))

            case "Temp" | "InlineTable" | "ArrayUnnest" | "Iteration" | "IterationScan" | "RegexSplit" | "SetOperation":
                attributes += "|ius" + str(len(raw["_ius"]))
                for iu in raw["_ius"]:
                    expressions.append(Expression("iu", ius[iu], "iu"))

            case "Window":
                for part in raw["partitions"]:
                    for key in part["key"]:
                        keytype = raw["values"][key["value"]]["_type"]
                        expressions.append(Expression("key", keytype, "key"))

                    for order in part["orders"]:
                        for o in order["order"]:
                            ordertype = raw["values"][o["value"]]["_type"]
                            expressions.append(Expression("order", ordertype, "order"))

                        for op in order["operations"]:
                            frame = op["frame"]
                            expressions.append(Expression("frame", "unknown", "frame|" + frame["range"] + frame["start"]["mode"] + "|" + frame["end"]["mode"]))

                            oplabel = "op_" + op["op"]["op"]
                            optype = ius[op["op"]["iu"]]
                            expressions.append(Expression(oplabel, optype, oplabel))

            case "Select":
                pass

            case _:
                log.print(label)
                log.print(raw)

    analyze_expression(system_representation, expressions)

    operators[operator_id] = Operator(label, attributes, set(expressions), expressions, children)


def analyze_plan(plan: str) -> dict[int, Operator]:
    operators = {}
    plan_dict = json.loads(plan)
    analyze_operator(plan_dict["queryPlan"], operators)
    return operators


def analyze_query(vals: dict) -> dict:
    r = {}
    r["query"] = vals["query"]
    r["state"] = vals["state"]
    r["time"] = vals["client_total_mean"]
    r["rows"] = vals["rows"]
    r["message"] = vals["message"]

    r["querylength"] = 0 if vals["plan"] == "" else len(json.loads(vals["plan"])["queryText"])

    extra = json.loads(vals['extra'], allow_nan=True)
    r["allocatedBytes"] = extra.get("query.allocatedBytes", 0)
    r["scannedRows"] = extra.get("tablescan.accessedRows", 0)
    r["scans"] = extra.get("tablescan.count", 0)
    r["joins"] = extra.get("join.hashJoins", 0) + extra.get("join.indexNLJoins", 0) + extra.get("join.bnlJoins", 0) + extra.get("join.singletonJoins", 0) + \
        extra.get("groupby.eagerRightGroupJoins", 0) + extra.get("groupby.hybridGroupJoins", 0) + extra.get("groupby.indexGroupJoins", 0)
    r["aggregations"] = extra.get("groupby.groupBys", 0) + \
        extra.get("groupby.eagerRightGroupJoins", 0) + extra.get("groupby.hybridGroupJoins", 0) + extra.get("groupby.indexGroupJoins", 0)
    r["sorts"] = extra.get("sort.sorts", 0) + extra.get("sort.limits", 0)
    r["windows"] = extra.get("window.windows", 0)
    r["iterations"] = extra.get("iteration.iterations", 0)

    r["ops"] = r["scans"] + r["joins"] + r["aggregations"] + r["sorts"] + r["windows"] + r["iterations"]
    return r


def analyze(csv_path: str) -> dict[str, Result]:
    def traverse_tree(tree, fun):
        q = deque([-1])
        while q:
            node = q.popleft()
            if node not in tree:
                raise Exception(f"Node {node} not in tree")

            op = tree[node]
            fun(op)
            for child in op.children:
                q.append(child)

    def compare_trees(tree1, tree2):
        q1 = deque([-1])
        q2 = deque([-1])
        while q1 and q2:
            node1 = q1.popleft()
            node2 = q2.popleft()
            if node1 not in tree1 or node2 not in tree2:
                raise Exception(f"Node {node1} or {node2} not in tree")

            op1 = tree1[node1]
            op2 = tree2[node2]

            # Compare label and number of children to early-exit on mismatch
            if op1.label != op2.label or len(op1.children) != len(op2.children):
                return False

            for child1 in op1.children:
                q1.append(child1)
            for child2 in op2.children:
                q2.append(child2)

        return not q1 and not q2

    # Open and read the CSV file
    log.info("Loading the data...")
    num_queries = 0
    num_errors = 0
    operators = {}
    distinct_trees = {}
    distinct_operators = {}
    queries = {}
    num_distinct_queries = 0
    num_trees = {}
    num_distinct_trees = {}
    with log.progress("Loading the data", total=0) as progress:
        with smart_open(csv_path, newline='', encoding='utf-8', search=True) as csvfile:
            reader = csv.DictReader(csvfile)

            for row in reader:
                num_queries += 1

                query = row['query']
                attr = analyze_query(row)
                progress.description(query)

                if row["state"] != "success" or row["plan"] == "":
                    num_errors += (row["state"] != "success")
                    queries[query] = Result(query, attr, 0, 0, {})
                    progress.advance()
                    continue

                tree = analyze_plan(row["plan"])
                signature = ""

                query_distinct_trees = 0
                query_distinct_operators = 0

                def f(op):
                    nonlocal query_distinct_operators
                    nonlocal signature
                    nonlocal num_operators
                    nonlocal distinct_operators
                    if op.label != "Result":
                        signature += "|" + op.label

                        if op.label not in operators:
                            operators[op.label] = 0
                            distinct_operators[op.label] = set()
                        operators[op.label] += 1

                        o = copy.deepcopy(op)
                        o.children = []

                        if o not in distinct_operators[op.label]:
                            query_distinct_operators += 1
                            distinct_operators[op.label].add(o)

                traverse_tree(tree, f)

                found = False
                if signature in distinct_trees:
                    for t in distinct_trees[signature]:
                        if compare_trees(tree, t):
                            found = True
                            break

                if len(tree) not in num_trees:
                    num_trees[len(tree)] = 0
                num_trees[len(tree)] += 1

                if not found:
                    if len(tree) not in num_distinct_trees:
                        num_distinct_trees[len(tree)] = 0
                    num_distinct_trees[len(tree)] += 1

                    if signature not in distinct_trees:
                        distinct_trees[signature] = []
                    query_distinct_trees += 1
                    distinct_trees[signature].append(tree)

                if query_distinct_trees > 0 or query_distinct_operators > 0:
                    num_distinct_queries += 1

                queries[query] = Result(query, attr, query_distinct_trees, query_distinct_operators, tree)
                progress.advance()

    log.info(f"Loaded {num_queries} queries with {num_errors} errors.")

    num_distinct_operators = 0
    num_operators = 0
    log.newline()
    for op in sorted(operators.keys()):
        num_distinct_operators += len(distinct_operators[op])
        num_operators += operators[op]
        log.info(f"{len(distinct_operators[op]):5} of {operators[op]:5} {op} operators are distinct ({(100 * len(distinct_operators[op]) / operators[op]):.2f}%).")

    log.newline()
    for op_count in sorted(num_distinct_trees.keys()):
        num_distinct_tree = num_distinct_trees[op_count]
        num_tree = num_trees.get(op_count, 0)
        log.info(f"{num_distinct_tree:5} of {num_tree:5} trees with {op_count:3} operators are distinct ({(100 * num_distinct_tree / num_tree):.2f}%).")

    log.newline()
    if num_operators > 0:
        log.info(f"{num_distinct_operators:5} of {num_operators:5} operators are distinct ({(100 * num_distinct_operators / num_operators):.2f}%).")
    num_distinct_trees = sum([len(ts) for ts in distinct_trees.values()])
    log.info(f"{num_distinct_trees:5} of {num_queries:5} queries have distinct trees ({(100 * num_distinct_trees / num_queries):.2f}%).")
    log.info(f"{num_distinct_queries:5} of {num_queries:5} queries are distinct ({(100 * num_distinct_queries / num_queries):.2f}%).")

    log.newline()

    return queries


def main():
    log.header("Compute distinct queries")

    # Get command line arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument("dataset", help="Dataset of the benchmark")
    argparser.add_argument("version", help="Version of the benchmark")
    argparser.add_argument("result", help="Result file")
    args = argparser.parse_args()

    queries = analyze(args.result)
    distinct_queries = [(query, result.distinct_trees, result.distinct_operators) for query, result in queries.items() if result.distinct_trees > 0 or result.distinct_operators > 0]

    distinct_csv = os.path.join(args.version, args.dataset, "distinct_queries.csv")
    log.info(f"Writing distinct queries to {distinct_csv} ...")
    with log.progress("Writing distinct queries", total=len(distinct_queries)) as progress:
        with smart_open(distinct_csv, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["query", "distinct_trees", "distinct_operators"])
            writer.writeheader()

            for query, query_distinct_trees, query_distinct_operators in distinct_queries:
                progress.description(query)
                writer.writerow({
                    "query": query,
                    "distinct_trees": query_distinct_trees,
                    "distinct_operators": query_distinct_operators
                })
                progress.advance()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.error(e)
        raise e
