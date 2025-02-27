SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    STRING_AGG(CONCAT(l.l_comment, ' (Order: ', o.o_orderkey, ')'), '; ') AS comments_summary
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
    p.p_name LIKE '%steel%' 
    AND s.s_comment NOT LIKE '%discount%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_discount) > 0.1
ORDER BY 
    total_quantity DESC, order_count ASC;