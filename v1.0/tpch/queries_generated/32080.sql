WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),

high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 5000
),

order_summary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count, SUM(l.l_extendedprice*(1-l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),

supplier_performance AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    GROUP BY ps.ps_partkey
),

final_report AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        SUM(os.total_revenue) AS total_orders,
        COALESCE(SUM(s.avg_supply_cost), 0) AS avg_cost,
        COUNT(DISTINCT sh.s_suppkey) AS supplier_count
    FROM high_value_customers c
    LEFT JOIN order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    LEFT JOIN supplier_performance s ON s.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = c.c_custkey)
    LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    fr.c_name,
    fr.total_orders,
    fr.avg_cost,
    fr.supplier_count
FROM final_report fr
ORDER BY fr.total_orders DESC, fr.avg_cost ASC
LIMIT 10;
