
SELECT p.p_name, 
       s.s_name, 
       c.c_name, 
       r.r_name, 
       COUNT(l.l_orderkey) AS order_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
       MAX(l.l_shipdate) AS last_ship_date,
       STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments,
       LEFT(p.p_comment, 20) AS short_comment
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 100.00
  AND l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY p.p_name, s.s_name, c.c_name, r.r_name, p.p_comment
HAVING COUNT(l.l_orderkey) > 5
ORDER BY total_revenue DESC;
