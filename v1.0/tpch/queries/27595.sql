WITH String_Processing_Benchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Part: ', p.p_name, ' supplied by: ', s.s_name) AS full_description,
        LENGTH(CONCAT('Part: ', p.p_name, ' supplied by: ', s.s_name)) AS description_length,
        SUBSTRING(s.s_comment, 1, 50) AS short_supplier_comment,
        REPLACE(p.p_comment, 'outdated', 'modern') AS updated_comment,
        TRIM(p.p_type) AS trimmed_part_type
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 10 AND 30
        AND s.s_acctbal > 1000.00
)
SELECT 
    AVG(description_length) AS avg_description_length,
    COUNT(*) AS total_entries,
    COUNT(DISTINCT trimmed_part_type) AS unique_part_types,
    COUNT(DISTINCT short_supplier_comment) AS unique_comments,
    STRING_AGG(updated_comment, '; ') AS aggregated_updated_comments
FROM 
    String_Processing_Benchmark;
