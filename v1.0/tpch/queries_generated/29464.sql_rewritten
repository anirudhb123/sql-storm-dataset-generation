SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names,
    STRING_AGG(DISTINCT n.n_name, '; ') AS nations_supplied,
    MAX(l.l_shipdate) AS last_ship_date
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
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 100;