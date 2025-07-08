
WITH String_Bench AS (
    SELECT 
        p.p_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS full_description,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'interesting', 'fascinating') AS modified_comment,
        UPPER(p.p_name) AS upper_part_name,
        LOWER(p.p_name) AS lower_part_name,
        LENGTH(p.p_name) AS name_length,
        LEFT(p.p_name, 5) AS name_prefix,
        RIGHT(p.p_name, 5) AS name_suffix
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    UPPER('Total unique part names: ') AS description,
    COUNT(DISTINCT p_name) AS unique_part_names,
    AVG(comment_length) AS avg_comment_length,
    STRING_AGG(DISTINCT full_description, '; ') AS concatenated_descriptions
FROM String_Bench
WHERE comment_length > 20
GROUP BY upper_part_name, description
ORDER BY unique_part_names DESC;
