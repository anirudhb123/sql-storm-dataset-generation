
SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_orderkey) AS unique_order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(s.s_comment, '; ') AS supplier_comments,
    STRING_AGG(c.c_comment, '; ') AS customer_comments
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    COUNT(o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
