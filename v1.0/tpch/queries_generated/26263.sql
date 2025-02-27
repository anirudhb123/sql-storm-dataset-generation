WITH SupplierParts AS (
    SELECT 
        s.s_name AS SupplierName,
        p.p_name AS PartName,
        p.p_brand AS Brand,
        ps.ps_supplycost AS SupplyCost,
        ps.ps_availqty AS AvailableQuantity,
        SUBSTRING(s.s_comment, 1, 30) AS ShortComment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
PartStatistics AS (
    SELECT 
        p_brand,
        COUNT(*) AS TotalSuppliers,
        SUM(ps_supplycost) AS TotalSupplyCost,
        AVG(ps_supplycost) AS AvgSupplyCost,
        MAX(ps_supplycost) AS MaxSupplyCost,
        MIN(ps_supplycost) AS MinSupplyCost
    FROM 
        SupplierParts
    GROUP BY 
        p_brand
)
SELECT 
    ps.p_brand,
    ps.TotalSuppliers,
    ps.TotalSupplyCost,
    ps.AvgSupplyCost,
    ps.MaxSupplyCost,
    ps.MinSupplyCost,
    STRING_AGG(sp.SupplierName || ' (' || sp.ShortComment || ')', '; ') AS SupplierDetails
FROM 
    PartStatistics ps
JOIN 
    SupplierParts sp ON ps.p_brand = sp.Brand
GROUP BY 
    ps.p_brand, ps.TotalSuppliers, ps.TotalSupplyCost, ps.AvgSupplyCost, ps.MaxSupplyCost, ps.MinSupplyCost
ORDER BY 
    ps.TotalSuppliers DESC;
