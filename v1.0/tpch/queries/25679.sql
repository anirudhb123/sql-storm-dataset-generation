SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN l.l_extendedprice ELSE NULL END) AS avg_building_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    r.r_name AS region_name
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
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
GROUP BY 
    s.s_name, r.r_name
ORDER BY 
    total_revenue DESC, supplier_name ASC;