SELECT 
    p.p_partkey, 
    p.p_name, 
    SUBSTRING(p.p_comment FROM 1 FOR 15) AS short_comment,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name ASC) AS region_names
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%' AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
HAVING 
    total_orders > 5
ORDER BY 
    total_returned_qty DESC, short_comment;
