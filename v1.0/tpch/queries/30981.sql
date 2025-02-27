WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
), 
AggregateSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY c.c_custkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_mfgr,
        COUNT(ps.ps_suppkey) AS SupplierCount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_mfgr
    HAVING COUNT(ps.ps_suppkey) > 5
)
SELECT 
    r.r_name AS RegionName,
    SUM(agg.TotalSales) AS TotalRegionSales,
    AVG(p.p_retailprice) AS AvgRetailPrice,
    MAX(p.SupplierCount) AS MaxSupplierCount,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(agg.TotalSales) DESC) AS RegionRank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN AggregateSales agg ON s.s_suppkey = agg.c_custkey
LEFT JOIN FilteredParts p ON s.s_nationkey = p.p_partkey
GROUP BY r.r_name
HAVING AVG(p.p_retailprice) IS NOT NULL
ORDER BY TotalRegionSales DESC;