
WITH StringAggregation AS (
    SELECT 
        s.s_name AS supplier_name,
        CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, 
               ' (', p.p_type, ') in ', r.r_name, ' region. Comment: ', s.s_comment) AS full_description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        LENGTH(s.s_name) > 10 
        AND p.p_size < 20
)
SELECT 
    supplier_name,
    STRING_AGG(full_description, '; ') AS concatenated_descriptions
FROM 
    StringAggregation
GROUP BY 
    supplier_name
ORDER BY 
    supplier_name;
