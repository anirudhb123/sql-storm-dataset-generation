SELECT 
    p.p_partkey,
    CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_info,
    s.s_name AS supplier_name,
    CONCAT('Region: ', r.r_name, ' - Comment: ', r.r_comment) AS region_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MIN(l.l_shipdate) AS first_ship_date,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
    p.p_retailprice > 50.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, s.s_name, r.r_name, r.r_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC,
    first_ship_date ASC
LIMIT 100;
