SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    SUBSTRING_INDEX(s.s_comment, ' ', 5) AS short_s_comment,
    CONCAT('Supplier: ', s.s_name, ' | Product: ', p.p_name) AS product_supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 50.00 
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND s.s_comment LIKE '%high quality%'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    order_count > 10
ORDER BY 
    avg_extended_price DESC, max_discount ASC;
