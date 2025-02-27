WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.suppkey = s.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
top_suppliers AS (
    SELECT s.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > 20000.00
),
order_summary AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
final_summary AS (
    SELECT DISTINCT c.c_custkey, c.c_name, o.total_orders, o.total_spent, l.total_revenue
    FROM customer c
    LEFT JOIN order_summary o ON c.c_custkey = o.o_custkey
    LEFT JOIN line_item_summary l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    WHERE c.c_mktsegment = 'BUILDING' AND (o.total_spent > 10000.00 OR o.total_orders IS NULL)
)
SELECT rh.n_name AS nation_name, COUNT(fs.c_custkey) AS customer_count, SUM(fs.total_spent) AS total_spent_customers
FROM final_summary fs
JOIN nation rh ON fs.c_custkey = rh.n_nationkey
LEFT OUTER JOIN top_suppliers ts ON ts.n_nationkey = rh.n_nationkey
WHERE ts.total_acctbal IS NULL
GROUP BY rh.n_name
ORDER BY total_spent_customers DESC
LIMIT 10;
