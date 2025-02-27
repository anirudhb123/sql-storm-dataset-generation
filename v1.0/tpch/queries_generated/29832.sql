SELECT 
    p.p_name,
    p.p_mfgr,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS product_description,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(AVG(l.l_extendedprice), 2) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', ') AS suppliers,
    MAX(DATE_FORMAT(o.o_orderdate, '%Y-%m')) AS last_order_month
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_type
HAVING 
    total_quantity > 100
ORDER BY 
    total_orders DESC, avg_price DESC
LIMIT 10;
