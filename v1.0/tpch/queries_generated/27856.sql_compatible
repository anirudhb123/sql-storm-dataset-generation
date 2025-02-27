
SELECT 
    CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_details,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS average_order_price
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
    p.p_retailprice > 100.00 
    AND s.s_acctbal > 5000.00 
    AND c.c_mktsegment = 'BUILD'
GROUP BY 
    p.p_name, p.p_brand, p.p_type, s.s_name, c.c_name
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    AVG(o.o_totalprice) DESC;
