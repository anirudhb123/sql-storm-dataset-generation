WITH StringData AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        CONCAT(s.s_name, ' - ', c.c_name, ' - ', p.p_name) AS combined_string,
        LENGTH(CONCAT(s.s_name, ' - ', c.c_name, ' - ', p.p_name)) AS length_of_combined_string
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    WHERE 
        p.p_size > 10
)
SELECT 
    part_name,
    supplier_name,
    customer_name,
    combined_string,
    length_of_combined_string,
    REPLACE(combined_string, ' ', '_') AS underscored_string,
    LOWER(combined_string) AS lower_case_string,
    UPPER(combined_string) AS upper_case_string,
    SUBSTRING(combined_string, 1, 20) AS substring_part
FROM 
    StringData
ORDER BY 
    length_of_combined_string DESC
LIMIT 100;
