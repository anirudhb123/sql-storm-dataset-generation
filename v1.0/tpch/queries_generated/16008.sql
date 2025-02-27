SELECT p.p_name, SUM(l.l_extendedprice) AS total_revenue
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
GROUP BY p.p_name
ORDER BY total_revenue DESC
LIMIT 10;
