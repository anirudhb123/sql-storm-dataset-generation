SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS average_order_value,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
    p.p_type LIKE '%metal%'
AND 
    o.o_orderdate >= DATE '1996-01-01'
AND 
    o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;