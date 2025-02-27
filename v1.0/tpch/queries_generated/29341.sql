SELECT 
    p.p_name,
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS product_info,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_address, ',', 1), ' ', -1) AS supplier_city,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        ELSE 'Normal Volume'
    END AS volume_category,
    LOWER(p.p_comment) AS lower_comment
FROM 
    part p
INNER JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
INNER JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
INNER JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size IN (10, 20, 30)
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000.00
ORDER BY 
    total_revenue DESC, supplier_city ASC;
