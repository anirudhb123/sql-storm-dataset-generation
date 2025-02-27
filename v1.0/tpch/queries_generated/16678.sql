SELECT l_shipmode, COUNT(*) AS total_orders
FROM lineitem
WHERE l_shipdate >= '2023-01-01'
GROUP BY l_shipmode
ORDER BY total_orders DESC;
