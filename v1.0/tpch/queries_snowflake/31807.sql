WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
)
, total_sales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, 
       SUM(total_price) AS total_revenue,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       (SELECT COUNT(DISTINCT o.o_orderkey) 
        FROM orders o 
        WHERE o.o_orderstatus = 'F' 
          AND o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year') AS completed_orders_last_year
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN total_sales ts ON o.o_orderkey = ts.o_orderkey
LEFT JOIN supplier s ON c.c_nationkey = s.s_nationkey
WHERE s.s_acctbal IS NOT NULL
  AND (r.r_name IS NOT NULL OR n.n_name IS NOT NULL)
GROUP BY r.r_name
HAVING AVG(s.s_acctbal) >= (SELECT AVG(s2.s_acctbal) FROM supplier s2)
ORDER BY total_revenue DESC;