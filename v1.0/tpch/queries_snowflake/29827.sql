
WITH RECURSIVE string_benchmark AS (
    SELECT
        p.p_name AS part_name,
        SUBSTR(p.p_name, 1, 5) AS substring_5,
        LENGTH(p.p_name) AS name_length,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9]', '') AS sanitized_comment,
        'Part: ' || p.p_name || 
        ' | Size: ' || p.p_size || 
        ' | Price: ' || CAST(p.p_retailprice AS varchar) AS formatted_info
    FROM 
        part p
    WHERE 
        p.p_size > 10

    UNION ALL

    SELECT
        s.s_name AS supplier_name,
        SUBSTR(s.s_name, 1, 5) AS substring_5,
        LENGTH(s.s_name) AS name_length,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9]', '') AS sanitized_comment,
        'Supplier: ' || s.s_name || 
        ' | Address: ' || s.s_address || 
        ' | Phone: ' || s.s_phone AS formatted_info
    FROM 
        supplier s
    JOIN 
        nation n ON n.n_nationkey = s.s_nationkey
    WHERE 
        n.n_name LIKE 'S%'
)

SELECT 
    COUNT(*) AS total_records,
    AVG(name_length) AS avg_length,
    STRING_AGG(formatted_info, ' | ') AS aggregated_info
FROM 
    string_benchmark
GROUP BY 
    substring_5, name_length, sanitized_comment, formatted_info;
