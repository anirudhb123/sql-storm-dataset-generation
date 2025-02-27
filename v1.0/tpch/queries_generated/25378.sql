SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Retail Price: ', FORMAT(p.p_retailprice, 2), ', Comment: ', p.p_comment) AS detailed_description,
    SUBSTRING_INDEX(s.s_comment, ' ', 10) AS short_supplier_comment,
    p.p_type,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity_sold
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
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    )
GROUP BY 
    p.p_partkey, s.s_suppkey
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    total_quantity_sold DESC, s.s_name ASC;
