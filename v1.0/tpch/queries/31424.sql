
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal * 0.9, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_custkey = sh.c_custkey
    WHERE sh.level < 3
),
top_products AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY total_revenue DESC
    LIMIT 5
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 3000
)
SELECT 
    sh.c_name, 
    sh.c_acctbal, 
    tp.p_name, 
    tp.total_revenue,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'No Supplier Account'
        ELSE CAST(s.s_acctbal AS varchar)
    END AS supplier_account_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_totalprice) AS max_order_price
FROM sales_hierarchy sh
LEFT JOIN orders o ON sh.c_custkey = o.o_custkey
LEFT JOIN top_products tp ON o.o_orderkey = tp.p_partkey
LEFT JOIN supplier_details s ON s.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = tp.p_partkey 
    ORDER BY ps.ps_supplycost 
    LIMIT 1
)
GROUP BY sh.c_name, sh.c_acctbal, tp.p_name, tp.total_revenue, s.s_acctbal
HAVING SUM(o.o_totalprice) > 10000
ORDER BY sh.c_acctbal DESC, tp.total_revenue DESC;
