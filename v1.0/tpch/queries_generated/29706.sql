WITH String_Benchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        CONCAT(p.p_name, ' - ', s.s_name) AS combined_name,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name)) AS combined_length,
        SUBSTRING(p.p_comment, 1, 10) AS part_comment_short,
        UPPER(s.s_name) AS supplier_name_upper,
        LOWER(c.c_name) AS customer_name_lower,
        REPLACE(n.n_name, 'land', '') AS modified_nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        LENGTH(p.p_name) > 10
    ORDER BY 
        combined_length DESC
    LIMIT 100
)
SELECT 
    part_name, 
    supplier_name, 
    customer_name, 
    nation_name, 
    combined_name, 
    combined_length, 
    part_comment_short, 
    supplier_name_upper, 
    customer_name_lower, 
    modified_nation_name 
FROM 
    String_Benchmark;
