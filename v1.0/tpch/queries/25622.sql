SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_retailprice,
    CONCAT('Supplier: ', s.s_name, ', Comment: ', s.s_comment) AS supplier_info,
    STRING_AGG(DISTINCT CONCAT('Customer Name: ', c.c_name, ', Address: ', c.c_address), '; ') AS customer_details,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND (s.s_comment LIKE '%urgent%' OR c.c_comment LIKE '%preferred%')
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice, s.s_name, s.s_comment
ORDER BY 
    total_quantity DESC, p.p_name ASC;
