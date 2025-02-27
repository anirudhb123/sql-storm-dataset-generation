SELECT l_shipmode, COUNT(*) AS ship_count
FROM lineitem
WHERE l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY l_shipmode
ORDER BY ship_count DESC;
