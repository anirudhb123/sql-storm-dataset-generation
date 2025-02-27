WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        SUBSTRING(p.p_brand FROM 1 FOR 5) AS brand_substring,
        CONCAT('Brand: ', p.p_brand, ' | Type: ', p.p_type) AS brand_type,
        LENGTH(p.p_container) AS container_length,
        REPLACE(p.p_comment, 'good', 'excellent') AS modified_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000 
        AND p.p_size BETWEEN 10 AND 20
)
SELECT 
    n.n_name,
    COUNT(DISTINCT sp.p_partkey) AS part_count,
    MAX(LENGTH(sp.upper_name)) AS max_upper_name_length,
    MIN(LENGTH(sp.lower_comment)) AS min_lower_comment_length,
    MAX(LENGTH(sp.modified_comment)) AS max_modified_comment_length,
    STRING_AGG(sp.brand_type, '; ') AS aggregated_brand_type
FROM 
    StringProcessing sp
JOIN 
    supplier s ON sp.p_partkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    part_count DESC
LIMIT 10;
