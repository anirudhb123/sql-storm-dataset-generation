SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(CONCAT('Order: ', o.o_orderkey, ', Date: ', o.o_orderdate), '; ') AS order_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name IN ('Germany', 'France'))
AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC;