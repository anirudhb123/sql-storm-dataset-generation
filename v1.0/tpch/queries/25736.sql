SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
WHERE 
    s.s_name LIKE 'Supplier%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_revenue DESC;