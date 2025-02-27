WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 500.00

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier sp ON ps.ps_partkey = sp.s_suppkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_info AS (
    SELECT c.c_custkey, c.c_name, r.r_name AS region
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ci.c_name,
    ci.region,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    ROW_NUMBER() OVER (PARTITION BY ci.region ORDER BY COALESCE(os.total_revenue, 0) DESC) AS revenue_rank
FROM customer_info ci
LEFT JOIN order_summary os ON ci.c_custkey = os.o_custkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ci.c_nationkey
WHERE ci.region IS NOT NULL
GROUP BY ci.c_custkey, ci.c_name, ci.region
HAVING COALESCE(os.total_revenue, 0) > 1000.00
ORDER BY revenue_rank
LIMIT 50;

