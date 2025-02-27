SELECT 
    p.p_name,
    CONCAT_WS(' - ', s.s_name, s.s_address, s.s_phone) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', n.n_comment), '; ') AS nations_served
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, s.s_address, s.s_phone
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_orders DESC, total_quantity DESC;
