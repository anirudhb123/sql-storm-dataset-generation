SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS part_details,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_nationkey = s.s_nationkey) AS total_customers_served
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
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_name, part_details, supplier_name, region_name
HAVING 
    total_orders > 5
ORDER BY 
    total_revenue DESC, p.p_name;
