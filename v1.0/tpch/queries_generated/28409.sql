SELECT 
    CONCAT(s.s_name, '(', s.s_phone, ')') AS supplier_info,
    SUBSTRING_INDEX(p.p_name, ' ', 1) AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_discount) > 0.1 THEN 'High Discount'
        WHEN SUM(l.l_discount) > 0.05 THEN 'Moderate Discount'
        ELSE 'No Discount'
    END AS discount_category
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
GROUP BY 
    supplier_info, part_name
HAVING 
    total_orders > 10
ORDER BY 
    total_revenue DESC, supplier_info;
