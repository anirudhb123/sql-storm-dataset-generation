SELECT 
    CONCAT(s.s_name, ' from ', na.n_name, ', ', r.r_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(o.o_orderdate) AS last_order_date
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
    nation na ON s.s_nationkey = na.n_nationkey
JOIN 
    region r ON na.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND
    p.p_brand LIKE 'Brand%'
GROUP BY 
    s.s_name, na.n_name, r.r_name
ORDER BY 
    total_revenue DESC, last_order_date DESC
LIMIT 10;