WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        COUNT(DISTINCT ps.ps_partkey) AS supply_count,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ': ', p.p_retailprice::text), '; ') AS part_details
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY supply_count DESC) AS rnk
    FROM 
        RankedSuppliers
)
SELECT 
    f.s_name, 
    f.nation_name, 
    f.supply_count, 
    f.part_details
FROM 
    FilteredSuppliers f
WHERE 
    f.rnk <= 5
ORDER BY 
    f.nation_name, f.supply_count DESC;
