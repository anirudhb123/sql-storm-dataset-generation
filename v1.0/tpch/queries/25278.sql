SELECT 
    SUBSTRING(s.s_name, 1, 10) AS short_supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS location,
    STRING_AGG(DISTINCT p.p_brand || ' (' || p.p_type || ')', ', ') AS product_brands
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND p.p_size > 10
GROUP BY 
    short_supplier_name, location
ORDER BY 
    total_revenue DESC;