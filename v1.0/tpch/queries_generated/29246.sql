WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_comment) AS lower_comment,
        UPPER(s.s_name) AS upper_supplier_name,
        REPLACE(p.p_comment, 'a', '@') AS comment_replaced,
        SUBSTRING(s.s_address, 1, 15) AS address_substring,
        CHAR_LENGTH(p.p_type) AS type_length,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, s.s_phone, p.p_comment, s.s_address
)
SELECT 
    p_partkey,
    p_name,
    supplier_info,
    name_length,
    lower_comment,
    upper_supplier_name,
    comment_replaced,
    address_substring,
    type_length,
    nations_supplied
FROM 
    StringBenchmark
WHERE 
    name_length > 10
ORDER BY 
    name_length DESC;
