SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer_combination,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    DATEDIFF(MAX(l.l_shipdate), MIN(l.l_shipdate)) AS shipping_duration_days,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipmode IN ('TRUCK', 'SHIP')
    AND o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY 
    c.c_name, s.s_name, p.p_name, r.r_name, n.n_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
