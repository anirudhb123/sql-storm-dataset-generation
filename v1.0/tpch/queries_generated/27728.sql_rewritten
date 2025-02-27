SELECT 
    CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Container: ', p.p_container) AS part_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    ROUND(AVG(p.p_retailprice), 2) AS avg_retail_price,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
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
    p.p_brand LIKE 'Brand%01' 
    AND p.p_type IN ('Type A', 'Type B', 'Type C')
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, p.p_container, r.r_name, n.n_name
ORDER BY 
    total_available_quantity DESC, avg_retail_price ASC
LIMIT 10;