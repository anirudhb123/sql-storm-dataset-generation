WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        CONCAT(SUBSTRING(p.p_name, 1, 10), '...', SUBSTRING(p.p_name, -5, 5)) AS truncated_name,
        LOWER(REPLACE(p.p_comment, ' ', '_')) AS formatted_comment,
        s.s_name,
        s.s_phone,
        c.c_name,
        c.c_mktsegment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    WHERE 
        LENGTH(p.p_name) > 15
)
SELECT 
    truncated_name,
    formatted_comment,
    COUNT(*) AS supplier_count,
    STRING_AGG(DISTINCT s_name, ', ') AS supplier_names
FROM 
    StringProcessing
GROUP BY 
    truncated_name, formatted_comment
ORDER BY 
    supplier_count DESC;
