SELECT l_shipmode, COUNT(*) AS count_orders
FROM lineitem
WHERE l_shipdate >= '2023-01-01'
GROUP BY l_shipmode
ORDER BY count_orders DESC;
