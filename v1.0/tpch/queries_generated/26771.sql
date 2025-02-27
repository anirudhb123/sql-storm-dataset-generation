SELECT 
    p.p_name, 
    p.p_brand, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS average_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND p.p_brand IN ('BrandA', 'BrandB')
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, short_comment, supplier_region_info
HAVING 
    total_orders > 5
ORDER BY 
    average_price DESC;
