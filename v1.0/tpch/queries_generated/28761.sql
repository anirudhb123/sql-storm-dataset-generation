WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COUNT(DISTINCT ps.ps_partkey) AS PartCount,
        SUM(ps.ps_supplycost) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), FilteredSuppliers AS (
    SELECT 
        R.s_suppkey, 
        R.s_name, 
        R.PartCount, 
        R.TotalSupplyCost, 
        n.n_name AS NationName
    FROM 
        RankedSuppliers R
    JOIN 
        nation n ON R.s_nationkey = n.n_nationkey
    WHERE 
        R.Rank <= 3
)
SELECT 
    F.NationName, 
    STRING_AGG(CONCAT(F.s_name, ' (Parts: ', F.PartCount, ', Cost: ', F.TotalSupplyCost, ')'), '; ') AS SupplierDetails
FROM 
    FilteredSuppliers F
GROUP BY 
    F.NationName
ORDER BY 
    F.NationName;
