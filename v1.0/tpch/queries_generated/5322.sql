WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT ns.n_nationkey) AS NationCount,
        SUM(CASE WHEN rs.SupplierRank <= 10 THEN 1 ELSE 0 END) AS TopSupplierCount
    FROM 
        region r
    JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    JOIN 
        RankedSuppliers rs ON ns.n_nationkey = (SELECT n_nationkey FROM supplier WHERE s_nationkey = ns.n_nationkey LIMIT 1)
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS RegionName,
    hs.NationCount,
    hs.TopSupplierCount,
    AVG(o.o_totalprice) AS AverageOrderPrice
FROM 
    HighValueSuppliers hs
JOIN 
    region r ON hs.r_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = (SELECT n_nationkey FROM nation WHERE n_regionkey = r.r_regionkey LIMIT 1)
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    o.o_orderdate >= '2023-01-01'
GROUP BY 
    r.r_name, hs.NationCount, hs.TopSupplierCount
ORDER BY 
    AverageOrderPrice DESC;
