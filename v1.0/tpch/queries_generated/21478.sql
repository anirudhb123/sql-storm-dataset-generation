WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5
)
SELECT 
    p.p_partkey,
    STRING_AGG(DISTINCT s.s_name, ', ') AS SupplierNames,
    COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS ReturnedQuantity,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank,
    MAX(CASE WHEN l.l_tax IS NULL THEN 0 ELSE l.l_tax END) AS MaxTax,
    MIN(CASE WHEN l.l_tax IS NULL THEN 1 ELSE l.tax END) AS MinTax,
    p.p_name || ' - ' || p.p_mfgr AS PartDetails
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
AND EXISTS (SELECT 1 
            FROM SupplierHierarchy sh 
            WHERE sh.s_suppkey = s.s_suppkey AND sh.level <= 2)
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_type
HAVING AVG(l.l_tax) > (SELECT AVG(l_tax) FROM lineitem WHERE l_discount < 0.05)
ORDER BY TotalRevenue DESC NULLS LAST;
