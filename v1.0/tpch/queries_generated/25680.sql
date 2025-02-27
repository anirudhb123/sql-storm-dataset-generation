SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Orders Found'
    END AS order_status,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name SEPARATOR ', '), ',', 3) AS top_regions
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 100
    AND o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY 
    p.p_name, s.s_name
HAVING 
    total_available_quantity > 50
ORDER BY 
    total_orders DESC, total_available_quantity ASC;
