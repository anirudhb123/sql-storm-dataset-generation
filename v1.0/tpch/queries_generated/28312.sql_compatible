
WITH StringAggregates AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        STRING_AGG(DISTINCT p.p_name, '; ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    nation_name,
    region_name,
    supplier_count,
    LENGTH(supplier_names) AS supplier_names_length,
    LENGTH(part_names) AS part_names_length,
    REPLACE(REPLACE(supplier_names, ' ', '_'), ',', '|') AS formatted_supplier_names,
    CONCAT('Parts available: ', COUNT(DISTINCT p.p_partkey)) AS part_availability_info
FROM 
    StringAggregates
CROSS JOIN part p
GROUP BY 
    nation_name, region_name, supplier_count, supplier_names, part_names;
