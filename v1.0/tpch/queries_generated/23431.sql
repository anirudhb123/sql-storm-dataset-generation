WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 

HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent,
        MAX(o.o_orderdate) AS LastPurchase
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), 

SupplierStatistics AS (
    SELECT
        n.n_name AS NationName,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        AVG(SUM(ps.ps_supplycost) / NULLIF(SUM(ps.ps_availqty), 0)) AS AvgSupplyCost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
)

SELECT 
    r.r_name AS RegionName,
    COALESCE(hc.c_name, 'No High-Value Customer') AS CustomerName,
    MAX(ss.SupplierCount) AS TotalSuppliers,
    SUM(CASE WHEN rs.rn = 1 THEN rs.TotalCost ELSE 0 END) AS TopSupplierCost,
    COUNT(DISTINCT ss.NationName) AS DistinctNations
FROM 
    region r
LEFT JOIN 
    HighValueCustomers hc ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = hc.c_nationkey)
JOIN 
    SupplierStatistics ss ON ss.NationName IN (SELECT DISTINCT n.n_name FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)))
GROUP BY 
    r.r_name, hc.c_name
HAVING 
    MAX(ss.SupplierCount) > 0 OR COALESCE(hc.c_name, '') <> ''
ORDER BY 
    RegionName;
