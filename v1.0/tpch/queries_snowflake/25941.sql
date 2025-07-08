
WITH string_aggregates AS (
    SELECT 
        s.s_name AS supplier_name,
        CONCAT(s.s_name, ' from ', s.s_address) AS full_info,
        TRIM(REPLACE(UPPER(s.s_comment), 'SUPPLIER', '')) AS sanitized_comment,
        LISTAGG(p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_comment
),
supplier_details AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        sa.supplier_name, 
        sa.full_info, 
        sa.sanitized_comment, 
        sa.part_names
    FROM 
        string_aggregates sa
    JOIN 
        supplier s ON sa.supplier_name = s.s_name 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name, 
    nation_name, 
    supplier_name, 
    full_info, 
    sanitized_comment, 
    part_names,
    LENGTH(sanitized_comment) AS sanitized_comment_length,
    COUNT(*) OVER (PARTITION BY region_name) AS supplier_count_per_region
FROM 
    supplier_details
WHERE 
    LENGTH(TRIM(part_names)) > 0 
ORDER BY 
    region_name, 
    nation_name, 
    supplier_name;
