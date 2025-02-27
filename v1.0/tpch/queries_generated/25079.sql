SELECT 
    p_name, 
    s_name, 
    CONCAT('Part: ', p_name, ' | Manufacturer: ', p_mfgr, ' | Supplier: ', s_name) AS details,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_quantity) AS total_quantity,
    AVG(l_extendedprice) AS average_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p_name LIKE '%wood%' 
    AND s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'GERMANY')
GROUP BY 
    p_name, s_name
HAVING 
    total_orders > 5
ORDER BY 
    total_quantity DESC, average_price ASC;
