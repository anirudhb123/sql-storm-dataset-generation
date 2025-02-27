SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    MAX(o.o_totalprice) AS max_total_price,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'ASIA%' 
    AND o.o_orderstatus = 'F'
GROUP BY 
    p.p_partkey, short_comment
HAVING 
    total_quantity > 100
ORDER BY 
    total_orders DESC, max_total_price DESC;
