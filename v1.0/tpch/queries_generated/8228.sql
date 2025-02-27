WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        ns.n_name AS NationName,
        rs.s_name AS SupplierName,
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.n_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.SupplierRank <= 3
)
SELECT 
    RegionName,
    NationName,
    SupplierName,
    TotalCost
FROM 
    TopSuppliers
ORDER BY 
    RegionName, NationName, TotalCost DESC;
