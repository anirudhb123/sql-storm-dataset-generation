SELECT 
    CONCAT(c.c_name, ' - ', r.r_name) AS customer_region,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT p.p_name, '; ') AS products_list
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    r.r_name LIKE 'Eu%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    CONCAT(c.c_name, ' - ', r.r_name)
ORDER BY 
    total_revenue DESC
LIMIT 10;