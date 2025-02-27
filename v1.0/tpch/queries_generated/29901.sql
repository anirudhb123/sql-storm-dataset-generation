SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE 0 
        END) AS total_returned,
    SUM(l.l_quantity) AS total_ordered,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT c.c_name ORDER BY c.c_custkey SEPARATOR ', '), ',', 5) AS top_customers
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size IN (10, 20, 30)
    AND p.p_brand LIKE 'BrandA%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey
HAVING 
    total_returned > 0
ORDER BY 
    total_ordered DESC, total_returned DESC;
