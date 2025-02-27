SELECT l_shipmode, COUNT(*) AS total_orders
FROM lineitem
WHERE l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY l_shipmode
ORDER BY total_orders DESC;
