WITH StringMetrics AS (
    SELECT 
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        REPLACE(p.p_comment, 's', 'S') AS modified_comment,
        SUBSTR(p.p_name, 1, 10) AS name_first_10,
        TRIM(p.p_comment) AS trimmed_comment,
        COUNT(*) OVER() AS total_parts
    FROM 
        part p
    WHERE 
        CHAR_LENGTH(p.p_name) > 5 AND 
        p.p_name LIKE '%steel%'
)
SELECT 
    sm.name_length,
    sm.name_upper,
    sm.name_lower,
    sm.modified_comment,
    sm.name_first_10,
    sm.trimmed_comment,
    COUNT(DISTINCT s.s_name) AS distinct_suppliers,
    COUNT(DISTINCT c.c_name) AS distinct_customers,
    AVG(o.o_totalprice) AS avg_order_total
FROM 
    StringMetrics sm
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = sm.p_name LIMIT 1)
LEFT JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey LIMIT 1)
LEFT JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
GROUP BY 
    sm.name_length, sm.name_upper, sm.name_lower, sm.modified_comment, sm.name_first_10, sm.trimmed_comment
ORDER BY 
    sm.name_length DESC, avg_order_total DESC;
