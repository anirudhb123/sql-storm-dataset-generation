SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT(r.r_name, ', ', n.n_name) AS location,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_methods,
    MAX(l.l_shipdate) AS last_ship_date
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
    p.p_retailprice > 100.00 
    AND o.o_orderdate >= '1996-01-01' 
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
ORDER BY 
    total_revenue DESC, average_quantity DESC
LIMIT 50;