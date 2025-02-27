WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankByRegion
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_regionkey
),
MaxRegionalCost AS (
    SELECT 
        n.r_regionkey, 
        MAX(TotalSupplyCost) AS MaxCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    GROUP BY 
        n.r_regionkey
)
SELECT 
    rs.s_suppkey, 
    rs.s_name, 
    rs.TotalSupplyCost, 
    n.n_name AS NationName, 
    r.r_name AS RegionName
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    MaxRegionalCost mrc ON rs.TotalSupplyCost = mrc.MaxCost AND n.n_regionkey = mrc.r_regionkey
WHERE 
    rs.RankByRegion = 1
ORDER BY 
    r.r_name, 
    rs.TotalSupplyCost DESC;
