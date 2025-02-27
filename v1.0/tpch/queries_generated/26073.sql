WITH String_Bench AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name) AS combined_info,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name)) AS combined_length,
        UPPER(p.p_name) AS upper_part_name,
        LOWER(s.s_name) AS lower_supplier_name,
        REPLACE(p.p_comment, 'fragile', 'delicate') AS updated_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_part_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        LENGTH(p.p_name) > 10
)
SELECT 
    COUNT(*) AS record_count,
    AVG(combined_length) AS avg_combined_length,
    MIN(upper_part_name) AS min_upper_part_name,
    MAX(lower_supplier_name) AS max_lower_supplier_name,
    LISTAGG(updated_comment, '; ') AS aggregated_comments
FROM 
    String_Bench;
