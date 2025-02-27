WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT sp.ps_suppkey, su.s_name, su.s_nationkey, sh.level + 1
    FROM partsupp sp
    JOIN supplier su ON sp.ps_suppkey = su.s_suppkey
    JOIN SupplierHierarchy sh ON sp.ps_partkey = sh.s_suppkey
)
SELECT 
    n.n_name AS Nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE l.l_shipdate >= '2021-01-01' AND l.l_shipdate < '2022-01-01'
GROUP BY n.n_name
ORDER BY TotalRevenue DESC
LIMIT 10;
