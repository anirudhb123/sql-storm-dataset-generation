SELECT l_shipmode, COUNT(*) AS shipping_count
FROM lineitem
WHERE l_shipdate >= '2023-01-01' AND l_shipdate < '2024-01-01'
GROUP BY l_shipmode
ORDER BY shipping_count DESC;
