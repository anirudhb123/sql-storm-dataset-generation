SELECT l.l_shipmode, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM lineitem l
WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
GROUP BY l.l_shipmode
ORDER BY revenue DESC;
