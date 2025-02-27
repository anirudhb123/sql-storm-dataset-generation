SELECT 
    c.c_name AS customer_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT p.p_name, ', ') AS parts_ordered
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC;