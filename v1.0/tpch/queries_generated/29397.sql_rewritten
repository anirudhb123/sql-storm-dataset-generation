SELECT s.s_name, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(p.p_retailprice) AS avg_part_price,
       STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), '; ') AS part_details,
       r.r_name AS region_name
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE c.c_mktsegment = 'BUILDING' 
  AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY s.s_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC;