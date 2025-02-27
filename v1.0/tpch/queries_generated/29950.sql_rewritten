SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    MAX(CASE WHEN o.o_orderdate >= '1997-01-01' THEN l.l_quantity ELSE 0 END) AS max_quantity_recent_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%high%'
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;