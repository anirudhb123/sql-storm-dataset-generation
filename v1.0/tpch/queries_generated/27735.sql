WITH StringAggregates AS (
    SELECT 
        s.s_name AS supplier_name,
        CONCAT(SUBSTRING(s.s_name, 1, 5), '...', SUBSTRING(s.s_name, LENGTH(s.s_name) - 4, 5)) AS truncated_name,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        STRING_AGG(DISTINCT p.p_type, ', ') AS part_types,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name
),
HighVolumeSuppliers AS (
    SELECT 
        sa.supplier_name,
        sa.truncated_name,
        sa.total_parts,
        sa.part_types
    FROM 
        StringAggregates sa
    WHERE 
        sa.total_parts > 10
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    hvs.supplier_name,
    hvs.truncated_name,
    hvs.part_types,
    CONCAT('Supplier ', hvs.supplier_name, ' offers ', hvs.total_parts, ' parts: ', hvs.part_types) AS supplier_details
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    HighVolumeSuppliers hvs ON hvs.supplier_name LIKE CONCAT('%', n.n_name, '%')
ORDER BY 
    r.r_name, n.n_name, hvs.total_parts DESC;
