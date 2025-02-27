WITH String_Aggregation AS (
    SELECT 
        p.p_name, 
        CONCAT_WS(' - ', s.s_name, c.c_name) AS supplier_customer,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_name) AS rn,
        CONCAT(SUBSTRING(s.s_comment, 1, 20), '...') AS supplier_comment_short
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    WHERE 
        p.p_size > 10 AND s.s_acctbal > 1000
), Filtered_Aggregation AS (
    SELECT 
        p_name,
        GROUP_CONCAT(supplier_customer SEPARATOR '; ') AS suppliers_customers,
        GROUP_CONCAT(supplier_comment_short SEPARATOR '; ') AS short_comments
    FROM 
        String_Aggregation
    WHERE 
        rn <= 3
    GROUP BY 
        p_name
)
SELECT 
    p_name, 
    suppliers_customers, 
    short_comments
FROM 
    Filtered_Aggregation
WHERE 
    LENGTH(suppliers_customers) > 50
ORDER BY 
    p_name DESC;
