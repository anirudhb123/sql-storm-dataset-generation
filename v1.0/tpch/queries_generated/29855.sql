SELECT 
    CONCAT('Supplier: ', s_name, ', Nation: ', n_name, ', Part: ', p_name, 
           ', Quantity: ', ps_availqty, ', Comment: ', ps_comment) AS supplier_info,
    COUNT(DISTINCT o_orderkey) AS total_orders
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.r_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%Amer%')
AND 
    s_comment NOT LIKE '%obsolete%'
GROUP BY 
    s_name, n_name, p_name, ps_availqty, ps_comment
ORDER BY 
    total_orders DESC, supplier_info ASC
LIMIT 50;
