WITH RegionalSuppliers AS (
    SELECT 
        n.n_name AS Nation, 
        r.r_name AS Region, 
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount, 
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name
),
TopRegions AS (
    SELECT 
        Region, 
        SUM(SupplierCount) AS TotalSuppliers
    FROM 
        RegionalSuppliers
    GROUP BY 
        Region
    ORDER BY 
        TotalSuppliers DESC
    LIMIT 5
)
SELECT 
    tr.Region,
    r.SupplierCount,
    r.TotalSupplyCost,
    p.p_name AS PartName,
    CASE 
        WHEN r.TotalSupplyCost > 10000 THEN 'High'
        WHEN r.TotalSupplyCost BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS CostCategory
FROM 
    TopRegions tr
JOIN 
    RegionalSuppliers r ON tr.Region = r.Region
JOIN 
    partsupp ps ON r.SupplierCount = (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_name = r.Nation)
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.TotalSupplyCost > 5000
ORDER BY 
    r.TotalSupplyCost DESC;
