SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
WHERE l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;
