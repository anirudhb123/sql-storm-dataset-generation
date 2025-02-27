SELECT l_partkey, SUM(l_quantity) AS total_quantity
FROM lineitem
WHERE l_shipdate >= '2023-01-01'
GROUP BY l_partkey
ORDER BY total_quantity DESC
LIMIT 10;
