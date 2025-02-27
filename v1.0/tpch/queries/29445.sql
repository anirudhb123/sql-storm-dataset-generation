WITH String_Benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        s.s_name AS supplier_name,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS combined_string,
        LENGTH(CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name)) AS string_length,
        LOWER(p.p_comment) AS lower_comment,
        UPPER(s.s_comment) AS upper_supplier_comment,
        REPLACE(p.p_comment, 'red', 'blue') AS modified_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_name LIKE '%widget%' 
        AND s.s_name NOT LIKE '%test%'
)
SELECT 
    AVG(string_length) AS avg_length,
    COUNT(*) AS total_records,
    MAX(lower_comment) AS max_lower_comment,
    MIN(upper_supplier_comment) AS min_upper_comment,
    STRING_AGG(modified_comment, '; ') AS concatenated_comments
FROM 
    String_Benchmark;
