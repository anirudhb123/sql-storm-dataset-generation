
SELECT 
    p.p_name,
    s.s_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_quantity ELSE 0 END) AS total_sold_quantity,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%special%'
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_quantity ELSE 0 END) > 100
ORDER BY 
    total_sold_quantity DESC, total_returned_quantity ASC;
