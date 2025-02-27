SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    GROUP_CONCAT(DISTINCT c.c_name ORDER BY c.c_name SEPARATOR ', ') AS customers,
    CONCAT(p.p_brand, ' - ', p.p_type) AS brand_and_type,
    CASE
        WHEN l.l_discount > 0.1 THEN 'High Discount'
        WHEN l.l_discount BETWEEN 0.05 AND 0.1 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category
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
WHERE 
    p.p_name LIKE '%Widget%'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
    AND l.l_returnflag = 'N'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
