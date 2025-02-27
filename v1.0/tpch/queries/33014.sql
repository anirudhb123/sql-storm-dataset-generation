
WITH RECURSIVE high_value_customers AS (
    SELECT c_custkey, c_name, c_acctbal, 1 AS depth
    FROM customer
    WHERE c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, hvc.depth + 1
    FROM customer c
    JOIN high_value_customers hvc ON c.c_acctbal > hvc.c_acctbal * 0.8
    WHERE hvc.depth < 3
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
order_rank AS (
    SELECT o.o_orderkey, o.o_custkey, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY os.total_order_value DESC) AS order_rank
    FROM order_summary os
    JOIN orders o ON os.o_custkey = o.o_custkey
)
SELECT 
    hvc.c_name,
    hvc.c_acctbal,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(os.total_order_value) AS max_order_value,
    COALESCE(SUM(si.total_supply_cost), 0) AS total_supply_cost,
    SUM(COALESCE(ns.supplier_count, 0)) AS nation_supplier_count
FROM high_value_customers hvc
LEFT JOIN order_rank o ON hvc.c_custkey = o.o_custkey
LEFT JOIN order_summary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN supplier_info si ON o.o_custkey = si.s_suppkey
LEFT JOIN nation_summary ns ON si.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey)
GROUP BY hvc.c_custkey, hvc.c_name, hvc.c_acctbal
HAVING COUNT(DISTINCT o.o_orderkey) > 2
ORDER BY hvc.c_acctbal DESC;
