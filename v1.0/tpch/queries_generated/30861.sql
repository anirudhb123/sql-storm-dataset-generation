WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sp.s_comment, sh.level + 1
    FROM supplier sp
    JOIN supplier_hierarchy sh ON sh.suppkey = sp.s_nationkey
    WHERE sp.s_acctbal > 5000
), 

order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
), 

customer_revenue AS (
    SELECT c.c_custkey, SUM(os.total_revenue) AS customer_revenue
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey
)

SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(COALESCE(sr.s_acctbal, 0)) AS total_supplier_acctbal,
    AVG(cr.customer_revenue) AS avg_revenue_per_customer
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sr ON n.n_nationkey = sr.s_nationkey
JOIN customer_revenue cr ON cr.customer_revenue IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY total_supplier_acctbal DESC;
