WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS OrderRank
    FROM 
        orders AS o 
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS SupplyCount,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        (SELECT COUNT(*) FROM partsupp WHERE ps_partkey = p.p_partkey) AS SupplierCount,
        (SELECT SUM(ps.ps_supplycost * ps.ps_availqty) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS TotalCost,
        MAX(p.p_retailprice) - MIN(p.p_retailprice) AS PriceRange
    FROM 
        part AS p
    GROUP BY 
        p.p_partkey
)

SELECT 
    r.r_name AS RegionName,
    SUM(COALESCE(ss.AvgSupplyCost, 0)) AS AverageSupplyCost,
    COUNT(DISTINCT ps.p_partkey) AS UniqueParts,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN TotalRevenue ELSE 0 END) AS CompletedOrderTotalRevenue,
    MAX(ps.PriceRange) AS MaxPriceRange
FROM 
    region AS r
LEFT JOIN 
    nation AS n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier AS s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = ps.ps_partkey
LEFT JOIN 
    PartStatistics pstat ON pstat.p_partkey = ps.ps_partkey
GROUP BY 
    r.r_name
HAVING 
    AVG(ss.AvgSupplyCost) IS NOT NULL AND 
    COUNT(DISTINCT n.n_nationkey) > 0
ORDER BY 
    RegionName DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM orders) % 5;

WITH RecursiveParts AS (
    SELECT 
        p.p_partkey,
        p.p_comment,
        1 AS RecursiveLevel
    FROM 
        part p
    WHERE 
        p.p_size < (SELECT AVG(p_size) FROM part)
    UNION ALL
    SELECT 
        p.p_partkey,
        CONCAT(pr.p_comment, ' - Recursive level ', rp.RecursiveLevel) AS RecursiveComment,
        rp.RecursiveLevel + 1
    FROM 
        RecursiveParts rp
    JOIN 
        part p ON rp.RecursiveLevel < 5
)
SELECT * FROM RecursiveParts;
