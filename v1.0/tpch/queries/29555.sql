
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS customer_segments,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS unique_ship_modes
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
    p.p_retailprice > 50 AND 
    o.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
