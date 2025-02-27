SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS average_returned_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_revenue DESC;