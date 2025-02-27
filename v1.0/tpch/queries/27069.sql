SELECT 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_region,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    supplier_region
ORDER BY 
    total_revenue DESC
LIMIT 10;