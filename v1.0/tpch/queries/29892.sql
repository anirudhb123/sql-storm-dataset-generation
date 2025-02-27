WITH SupplierInfo AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied,
        SUM(ps.ps_supplycost) AS TotalSupplyCost,
        STRING_AGG(DISTINCT CONCAT('Part: ', p.p_name, ', Comment: ', p.p_comment), '; ') AS PartDetails
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationInfo AS (
    SELECT 
        n.n_name,
        SUM(si.TotalPartsSupplied) AS TotalSuppliers,
        SUM(si.TotalSupplyCost) AS TotalCosts,
        STRING_AGG(si.s_name, ', ') AS Suppliers
    FROM 
        nation n
    JOIN 
        SupplierInfo si ON n.n_nationkey = si.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ni.n_name AS Nation,
    ni.TotalSuppliers,
    ni.TotalCosts,
    ni.Suppliers,
    SUBSTRING(ni.Suppliers, 1, 100) AS SampleSuppliers
FROM 
    NationInfo ni
WHERE 
    ni.TotalCosts > 10000
ORDER BY 
    ni.TotalCosts DESC;
