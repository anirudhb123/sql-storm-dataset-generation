SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(CASE WHEN l.l_shipdate < '1996-01-01' THEN l.l_shipdate END) AS earliest_ship_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    SUBSTR(p.p_comment, 1, 15) AS short_comment,
    REPLACE(p.p_brand, 'BrandA', 'BrandX') AS modified_brand
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
ORDER BY 
    total_revenue DESC
LIMIT 50;
