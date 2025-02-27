WITH string_benchmark AS (
    SELECT 
        p.p_name,
        CONCAT('Part Name: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS detailed_info,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(REPLACE(p.p_comment, 'a', ''), 'e', '') AS reduced_comment,
        UPPER(SUBSTRING(p.p_name, 1, 10)) AS upper_part_name,
        LOWER(p.p_brand) AS lower_brand,
        TRIM(p.p_type) AS trimmed_type
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
)
SELECT 
    sb.detailed_info,
    sb.comment_length,
    sb.reduced_comment,
    sb.upper_part_name,
    sb.lower_brand,
    sb.trimmed_type,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    string_benchmark sb
JOIN 
    partsupp ps ON ps.ps_partkey = (SELECT p_partkey FROM part WHERE p_name = sb.p_name LIMIT 1)
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    sb.detailed_info, sb.comment_length, sb.reduced_comment, sb.upper_part_name, sb.lower_brand, sb.trimmed_type
ORDER BY 
    sb.comment_length DESC, supplier_count ASC
LIMIT 10;
