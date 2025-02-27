WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    c.c_name AS CustomerName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalRevenue,
    AVG(CASE WHEN li.l_discount > 0.1 THEN li.l_extendedprice ELSE NULL END) AS AvgDiscountedPrice,
    MAX(sh.level) AS MaxSupplierLevel,
    r.r_name AS RegionName
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem li ON o.o_orderkey = li.l_orderkey
JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN region r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE o.o_orderstatus = 'O'
  AND li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY c.c_name, r.r_name
HAVING TotalRevenue > (SELECT AVG(TotalRevenue) FROM (
    SELECT SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalRevenue
    FROM lineitem li
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    GROUP BY o.o_custkey
) AS AvgRevenue)
ORDER BY TotalOrders DESC, TotalRevenue DESC
LIMIT 10;
