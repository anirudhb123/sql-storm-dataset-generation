SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales
FROM lineitem
WHERE l_shipdate >= '2023-01-01' AND l_shipdate < '2024-01-01'
GROUP BY l_orderkey
ORDER BY total_sales DESC
LIMIT 10;
