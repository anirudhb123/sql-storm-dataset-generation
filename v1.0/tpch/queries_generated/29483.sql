SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    GROUP_CONCAT(DISTINCT l.l_shipmode ORDER BY l.l_shipmode SEPARATOR ', ') AS shipping_methods,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey
HAVING 
    total_revenue > 50000
ORDER BY 
    total_revenue DESC;
