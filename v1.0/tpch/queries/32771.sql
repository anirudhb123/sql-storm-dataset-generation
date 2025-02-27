
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 0.9, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT n.n_name, 
       r.r_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END) AS avg_returned_quantity,
       COUNT(DISTINCT CASE WHEN l.l_discount > 0.05 THEN o.o_orderkey END) AS discounted_orders,
       s.s_name
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier_hierarchy sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
  AND l.l_shipdate IS NOT NULL
  AND (l.l_discount IS NOT NULL AND l.l_discount < 0.15)
GROUP BY n.n_name, r.r_name, s.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY total_revenue DESC
LIMIT 100;
