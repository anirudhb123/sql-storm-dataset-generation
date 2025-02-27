WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        n.n_name AS nation,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
)
SELECT 
    r.r_name,
    COUNT(ranked_supplier.nation) AS supplier_count,
    STRING_AGG(CONCAT(ranked_supplier.s_name, ' (', ranked_supplier.part_count, ' parts)') ORDER BY ranked_supplier.part_count DESC) AS supplier_list,
    SUM(ranked_supplier.total_supply_cost) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    RankedSuppliers ranked_supplier ON r.r_name = ranked_supplier.nation
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_cost DESC;
