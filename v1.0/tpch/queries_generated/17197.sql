SELECT l_orderkey, SUM(l_extendedprice) AS total_extended_price
FROM lineitem
WHERE l_shipdate >= '2023-01-01' AND l_shipdate < '2024-01-01'
GROUP BY l_orderkey
ORDER BY total_extended_price DESC
LIMIT 10;
