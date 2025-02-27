WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS Region,
        ns.n_name AS Nation,
        rs.s_name AS SupplierName,
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.n_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 3
)
SELECT 
    Region,
    Nation,
    STRING_AGG(SupplierName, ', ') AS TopSuppliers,
    SUM(TotalSupplyCost) AS TotalCost
FROM 
    TopSuppliers
GROUP BY 
    Region, Nation
ORDER BY 
    Region, TotalCost DESC;
