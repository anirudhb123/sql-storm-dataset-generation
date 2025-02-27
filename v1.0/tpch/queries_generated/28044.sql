SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Available Quantity: ', ps_availqty, 
           ', Cost: $', FORMAT(ps_supplycost, 2), 
           ', Comments: ', ps_comment) AS benchmark_string
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(ps_comment) > 50
    AND p_brand LIKE 'Brand%'
    AND s.s_address LIKE '%Street%'
ORDER BY 
    s_name, p_name DESC
LIMIT 100;
