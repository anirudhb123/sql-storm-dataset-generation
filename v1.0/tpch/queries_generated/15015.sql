SELECT p_pPartkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
GROUP BY p_partkey
ORDER BY revenue DESC
LIMIT 10;
