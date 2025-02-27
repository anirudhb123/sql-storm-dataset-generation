SELECT p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN customer c ON c.c_nationkey = s.s_nationkey
JOIN orders o ON o.o_custkey = c.c_custkey
WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
GROUP BY p.p_brand
ORDER BY total_revenue DESC
LIMIT 10;
