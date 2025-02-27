SELECT s.s_name AS supplier_name, 
       p.p_name AS part_name, 
       COUNT(l.l_orderkey) AS order_count, 
       STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
FROM supplier s 
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN part p ON ps.ps_partkey = p.p_partkey 
JOIN lineitem l ON p.p_partkey = l.l_partkey 
JOIN orders o ON l.l_orderkey = o.o_orderkey 
JOIN customer c ON o.o_custkey = c.c_custkey 
JOIN nation n ON s.s_nationkey = n.n_nationkey 
WHERE l.l_shipdate >= '1997-01-01' 
  AND l.l_shipdate <= '1997-12-31' 
  AND p.p_comment LIKE '%special%' 
GROUP BY s.s_name, p.p_name 
ORDER BY total_revenue DESC, order_count DESC 
LIMIT 10;