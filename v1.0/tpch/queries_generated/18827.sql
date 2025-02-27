SELECT SUM(l_extendedprice) AS total_revenue
FROM lineitem
WHERE l_shipdate >= '2023-01-01' AND l_shipdate < '2024-01-01';
