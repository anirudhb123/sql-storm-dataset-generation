SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_type, ', ') AS part_types,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
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
    l.l_shipmode IN ('AIR', 'TRUCK')
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-10-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, r.r_name, n.n_name
ORDER BY 
    revenue DESC, total_orders DESC
LIMIT 100;