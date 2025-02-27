SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_totalprice) AS max_order_value,
    MIN(o.o_orderdate) AS first_order_date,
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_comment LIKE '%quality%'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_quantity DESC, max_order_value DESC
LIMIT 10;