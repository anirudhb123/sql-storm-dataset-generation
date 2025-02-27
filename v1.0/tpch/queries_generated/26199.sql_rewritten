SELECT 
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_details,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_name LIKE '%widget%'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;