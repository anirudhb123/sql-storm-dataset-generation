WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), FilteredSuppliers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY s_name ORDER BY part_count DESC) AS rn
    FROM 
        RankedSuppliers
    WHERE 
        total_supply_cost > 1000
)
SELECT 
    s.s_name,
    s.part_count,
    s.total_supply_cost,
    s.part_names
FROM 
    FilteredSuppliers s
WHERE 
    rn = 1
ORDER BY 
    s.total_supply_cost DESC;
