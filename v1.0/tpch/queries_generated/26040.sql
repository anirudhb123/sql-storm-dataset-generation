SELECT 
    p.p_name,
    p.p_size,
    s.s_name,
    s.s_address,
    SUBSTRING(p.p_comment FROM 1 FOR 25) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    CASE 
        WHEN LENGTH(s.s_comment) > 50 THEN 'Long Comment' 
        ELSE 'Short Comment' 
    END AS comment_length,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey 
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey 
WHERE 
    p.p_size BETWEEN 10 AND 50
GROUP BY 
    p.p_name, p.p_size, s.s_name, s.s_address, short_comment, comment_length
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    avg_order_price DESC, p.p_name ASC
LIMIT 100;
