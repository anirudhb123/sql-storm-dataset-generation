WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
total_sales AS (
    SELECT l.l_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_suppkey
),
filtered_sales AS (
    SELECT s.s_suppkey, s.s_name, COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM supplier s
    LEFT JOIN total_sales ts ON s.s_suppkey = ts.l_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(s.total_revenue) AS average_revenue, 
    COUNT(s.s_suppkey) FILTER (WHERE s.total_revenue > (SELECT AVG(total_revenue) FROM filtered_sales)) AS high_revenue_count
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier_hierarchy sh ON sh.s_suppkey = n.n_nationkey
JOIN filtered_sales s ON s.s_suppkey = sh.s_suppkey
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
)
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1 AND 
       AVG(s.total_revenue) IS NOT NULL
ORDER BY average_revenue DESC
LIMIT 10 OFFSET 5;
