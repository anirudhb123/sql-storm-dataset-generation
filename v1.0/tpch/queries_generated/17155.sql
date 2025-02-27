SELECT l_shipmode, COUNT(*) AS order_count
FROM lineitem
WHERE l_shipdate >= '2023-01-01'
GROUP BY l_shipmode
ORDER BY order_count DESC;
