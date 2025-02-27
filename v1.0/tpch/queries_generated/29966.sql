WITH String_Analysis AS (
    SELECT
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        TRIM(p.p_comment) AS trimmed_comment,
        CASE 
            WHEN POSITION('green' IN p.p_comment) > 0 THEN 'Contains Green'
            ELSE 'Does Not Contain Green'
        END AS comment_contains_green,
        COUNT(DISTINCT s.s_nationkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY 
        p.p_name, p.p_comment
)
SELECT 
    name_length, 
    AVG(supplier_count) AS avg_supplier_count, 
    AVG(customer_count) AS avg_customer_count, 
    COUNT(*) AS total_names,
    SUM(CASE WHEN comment_contains_green = 'Contains Green' THEN 1 ELSE 0 END) AS count_contains_green
FROM 
    String_Analysis
WHERE 
    name_length > 10
GROUP BY 
    name_length
ORDER BY 
    name_length DESC;
