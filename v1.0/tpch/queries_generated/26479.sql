SELECT 
    CONCAT(c.c_name, ' from ', r.r_name) AS customer_info,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_items,
    MAX(o.o_orderdate) AS last_order_date,
    MIN(o.o_orderdate) AS first_order_date,
    AVG(l.l_quantity) AS avg_quantity_per_order
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
WHERE 
    r.r_name LIKE 'Europe%'
GROUP BY 
    c.c_name, r.r_name
HAVING 
    COUNT(o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
