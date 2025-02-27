SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(CONCAT('Order: ', o.o_orderkey, ', Date: ', o.o_orderdate, ', Price: ', o.o_totalprice), '; ') AS order_details
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
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;