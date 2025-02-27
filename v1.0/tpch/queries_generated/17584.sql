SELECT l.orderkey, SUM(l.extendedprice * (1 - l.discount)) AS revenue
FROM lineitem l
WHERE l.shipdate >= '2023-01-01' AND l.shipdate < '2023-12-31'
GROUP BY l.orderkey
ORDER BY revenue DESC
LIMIT 10;
