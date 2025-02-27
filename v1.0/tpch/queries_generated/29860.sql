SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name) AS supplier_part_info,
    LENGTH(s_comment) AS supplier_comment_length,
    SUBSTRING_INDEX(s_address, ' ', 1) AS first_word_of_address,
    REPLACE(p_comment, 'good', 'excellent') AS modified_part_comment,
    COUNT(DISTINCT c_custkey) AS unique_customers
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    orders o ON o.o_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = s.s_nationkey LIMIT 1)
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
WHERE 
    LENGTH(p_name) > 10
GROUP BY 
    s_name, p_name
HAVING 
    unique_customers > 5
ORDER BY 
    supplier_part_info ASC, supplier_comment_length DESC;
