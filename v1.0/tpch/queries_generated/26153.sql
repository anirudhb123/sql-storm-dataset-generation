SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    CONCAT(LEFT(p.p_name, 15), '...', LEFT(s.s_name, 15), '...') AS abbreviated_names
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%metal%' 
    AND s.s_comment NOT LIKE '%fragile%'
GROUP BY 
    p.p_name, 
    s.s_name
HAVING 
    total_quantity > 10
ORDER BY 
    total_orders DESC, 
    total_quantity DESC;
