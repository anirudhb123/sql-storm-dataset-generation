SELECT 
    p.p_name, 
    s.s_name,
    SUM(l.l_quantity) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS part_details,
    SUBSTRING_INDEX(s.s_comment, ' ', 5) AS supplier_comment_excerpt
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
WHERE 
    p.p_retailprice > 50.00 AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' AND 
    s.s_acctbal > 1000.00
GROUP BY 
    p.p_name, s.s_name, p.p_mfgr, p.p_brand, p.p_type
HAVING 
    total_quantity > 100
ORDER BY 
    total_orders DESC, total_quantity DESC;
