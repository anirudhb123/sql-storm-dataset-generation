WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN partsupp ps ON s2.s_suppkey = ps.ps_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_retailprice > 100)
)

SELECT 
    r.r_name AS Region, 
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    SUM(o.o_totalprice) AS TotalSales,
    AVG(s.s_acctbal) AS AvgSupplierAccountBalance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS Suppliers,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(o.o_totalprice) DESC) AS RegionRank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
LEFT JOIN supplier s ON sh.s_nationkey = s.s_nationkey
WHERE o.o_orderstatus IN ('O', 'F') 
AND (o.o_orderdate BETWEEN DATE '2023-01-01' AND CURRENT_DATE OR o.o_orderdate IS NULL)
GROUP BY r.r_name, n.n_name
ORDER BY Region, TotalSales DESC;
