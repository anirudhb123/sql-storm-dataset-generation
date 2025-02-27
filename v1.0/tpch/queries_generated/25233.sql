WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        c.c_name,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS full_description,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name)) AS description_length,
        SUBSTRING(p.p_comment, 1, 20) AS truncated_comment,
        REPLACE(p.p_comment, 'quality', '****') AS sanitized_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    WHERE 
        LENGTH(p.p_name) > 5
)
SELECT 
    COUNT(*) AS total_records,
    AVG(description_length) AS avg_description_length,
    MAX(description_length) AS max_description_length,
    MIN(description_length) AS min_description_length,
    STRING_AGG(truncated_comment, '; ') AS combined_comments,
    STRING_AGG(sanitized_comment, '; ') AS sanitized_comments
FROM 
    StringProcessing;
