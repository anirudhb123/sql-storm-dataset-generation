WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS detailed_info,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'quality', 'excellence') AS adjusted_comment,
        UPPER(SUBSTRING(p.p_name, 1, 10)) AS upper_part_name,
        LOWER(p.p_brand) AS lower_brand
    FROM 
        part p
    WHERE 
        p.p_size > 10
)
SELECT 
    STRING_AGG(detailed_info, '; ') AS aggregated_info,
    AVG(comment_length) AS avg_comment_length,
    MAX(upper_part_name) AS max_upper_part_name,
    MIN(lower_brand) AS min_lower_brand
FROM 
    StringProcessing;
