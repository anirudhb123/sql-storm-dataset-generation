
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS full_name, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 
           CONCAT(sh.full_name, ' > ', s.s_name) AS full_name, 
           sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
)

SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(o.o_totalprice) AS total_revenue,
       MAX(l.l_extendedprice) AS max_lineitem_price,
       AVG(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END) AS avg_discounted_price,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE o.o_orderstatus = 'O' 
  AND (l.l_shipdate >= DATE '1997-01-01' OR l.l_shipdate IS NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 100
ORDER BY total_revenue DESC, r.r_name;
