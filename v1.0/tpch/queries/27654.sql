
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROUND(AVG(l.l_quantity), 2) AS average_quantity,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    STRING_AGG(DISTINCT s.s_name, ', ' ORDER BY s.s_name) AS top_suppliers
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_brand IN ('Brand#1', 'Brand#2', 'Brand#3')
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
