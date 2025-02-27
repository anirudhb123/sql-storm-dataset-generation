SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_methods,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Revenue'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
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
    p.p_name ILIKE '%Steel%' AND
    o.o_orderstatus = 'F'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, r.r_name
ORDER BY 
    total_revenue DESC;
