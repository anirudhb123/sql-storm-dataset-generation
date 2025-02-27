SELECT l_shipmode, COUNT(*) AS shipping_count
FROM lineitem
WHERE l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY l_shipmode
ORDER BY shipping_count DESC;
