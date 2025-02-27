WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS HierarchyLevel
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.HierarchyLevel + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
)

SELECT 
    n.n_name AS NationName,
    r.r_name AS RegionName,
    COUNT(DISTINCT s.s_suppkey) AS TotalSuppliers,
    SUM(COALESCE(ps.ps_availqty, 0)) AS TotalAvailableQuantity,
    AVG(s.s_acctbal) AS AvgAccountBalance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS SupplierNames,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS LastFinishedOrder,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS DiscountedRevenue
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = ps.ps_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE n.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_comment IS NOT NULL)
GROUP BY n.n_name, r.r_name
HAVING COUNT(s.s_suppkey) > 0
ORDER BY AvgAccountBalance DESC
LIMIT 10;
