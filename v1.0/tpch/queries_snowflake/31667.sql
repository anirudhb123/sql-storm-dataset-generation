WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 5
),
total_order_value AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, t.total_value
    FROM total_order_value t
    JOIN orders o ON t.o_orderkey = o.o_orderkey
    WHERE t.total_value > (SELECT AVG(total_value) FROM total_order_value)
),
nation_supplier AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
),
joined_data AS (
    SELECT n.n_name, COALESCE(ns.total_supply_cost, 0) AS total_supply_cost, COALESCE(SUM(t.total_value), 0) AS order_total_value
    FROM nation n
    LEFT JOIN nation_supplier ns ON n.n_name = ns.n_name
    LEFT JOIN high_value_orders t ON n.n_nationkey = t.o_orderkey
    GROUP BY n.n_name, ns.total_supply_cost
)
SELECT
    j.n_name,
    j.total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY j.total_supply_cost DESC) AS rank,
    CASE 
        WHEN j.total_supply_cost IS NULL THEN 'No Data'
        ELSE 'Data Available'
    END AS supply_status
FROM joined_data j
WHERE j.order_total_value > 10000
ORDER BY rank DESC
LIMIT 10;
