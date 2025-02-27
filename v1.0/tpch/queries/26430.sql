SELECT 
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_shipment_date,
    MIN(l.l_shipdate) AS first_shipment_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS products_ordered,
    r.r_name AS region_name
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
    c.c_acctbal > 0 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_revenue DESC, last_shipment_date DESC;