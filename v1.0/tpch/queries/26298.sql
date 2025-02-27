SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    r.r_name AS region_name,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    part p ON l.l_partkey = p.p_partkey 
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-10-01' 
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 100;