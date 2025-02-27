SELECT 
    CONCAT_WS(' ', c.c_name, c.c_address) AS customer_info,
    CONCAT_WS(', ', r.r_name, n.n_name) AS location_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, '; ') AS product_list,
    l.l_shipmode AS shipping_method
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
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate <= '1997-12-31'
    AND o.o_orderstatus = 'F'
GROUP BY 
    customer_info, location_info, l.l_shipmode
ORDER BY 
    total_revenue DESC
LIMIT 10;