WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        n.n_name AS NationName,
        rs.s_name AS SupplierName,
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.SupplierRank <= 3
)

SELECT 
    RegionName,
    NationName,
    STRING_AGG(SupplierName || ' (' || TotalSupplyCost || ')', ', ') AS TopSuppliers
FROM 
    TopSuppliers
GROUP BY 
    RegionName, NationName
ORDER BY 
    RegionName, NationName;
