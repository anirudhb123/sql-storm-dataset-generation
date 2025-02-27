SELECT p_pmfgr, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
WHERE o_orderdate >= '2023-01-01' AND o_orderdate < '2023-12-31'
GROUP BY p_mfgr
ORDER BY revenue DESC
LIMIT 10;
