SELECT 
    CONCAT('Product: ', p_name, ' | Brand: ', p_brand, ' | Type: ', p_type) AS product_info,
    REPLACE(p_comment, 'old', 'new') AS updated_comment,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUBSTRING_INDEX(c.c_name, ' ', 1) AS first_customer_name,
    GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name ASC SEPARATOR ', ') AS regions_supplied
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
WHERE 
    p.p_size > 10 AND
    s.s_acctbal < 5000
GROUP BY 
    product_info, updated_comment
HAVING 
    supplier_count > 2
ORDER BY 
    first_customer_name DESC;
