SELECT l_shipmode, COUNT(*) AS count_order
FROM lineitem
WHERE l_shipdate >= '2023-01-01'
GROUP BY l_shipmode
ORDER BY count_order DESC;
