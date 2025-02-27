WITH StringAggregation AS (
    SELECT 
        s.s_name,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), '; ') AS part_details,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name
)
SELECT 
    ra.r_name AS region_name,
    sa.s_name AS supplier_name,
    sa.part_details,
    sa.total_parts
FROM 
    region ra
JOIN 
    nation n ON n.n_regionkey = ra.r_regionkey
JOIN 
    supplier sa ON sa.s_nationkey = n.n_nationkey
LEFT JOIN 
    StringAggregation sa ON sa.s_name = sa.s_name
WHERE 
    sa.total_parts > 5
ORDER BY 
    ra.r_name, sa.s_name;
