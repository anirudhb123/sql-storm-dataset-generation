SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
WHERE l_shipdate >= '2022-01-01' AND l_shipdate < '2022-02-01'
GROUP BY p_brand
ORDER BY revenue DESC;
