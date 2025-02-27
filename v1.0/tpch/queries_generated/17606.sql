SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM part 
JOIN lineitem ON p_partkey = l_partkey 
WHERE l_shipdate >= '2023-01-01' 
GROUP BY p_name 
ORDER BY revenue DESC 
LIMIT 10;
