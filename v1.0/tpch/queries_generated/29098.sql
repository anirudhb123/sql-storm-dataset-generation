SELECT 
    s.s_name AS supplier_name,
    SUM(CASE WHEN l_discount > 0 THEN l_extendedprice * (1 - l_discount) ELSE l_extendedprice END) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE NULL END) AS avg_returned_quantity,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p.p_name ORDER BY p.p_name SEPARATOR ', '), ', ', 5) AS top_parts
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
WHERE 
    o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
AND 
    s.s_acctbal > 0
GROUP BY 
    s.s_name
HAVING 
    total_orders > 10
ORDER BY 
    total_revenue DESC
LIMIT 10;
