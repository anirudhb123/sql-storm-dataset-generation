WITH StringProcessing AS (
    SELECT 
        p.p_name,
        s.s_name,
        c.c_name,
        n.n_name,
        r.r_name,
        LENGTH(p.p_comment) AS comment_length,
        UPPER(s.s_comment) AS supplier_comment_upper,
        LOWER(c.c_comment) AS customer_comment_lower,
        CONCAT(n.n_name, ' ', r.r_name) AS region_nation_concat,
        REPLACE(p.p_comment, 'obsolete', 'updated') AS updated_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_part_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p_name,
    s_name,
    c_name,
    comment_length,
    supplier_comment_upper,
    customer_comment_lower,
    region_nation_concat,
    updated_comment,
    short_part_name
FROM 
    StringProcessing
WHERE 
    comment_length > 20
ORDER BY 
    region_nation_concat, p_name;
