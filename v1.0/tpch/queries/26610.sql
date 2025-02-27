SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Type: ', p.p_type) AS product_info,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), '; ') AS customer_details
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice BETWEEN 50.00 AND 200.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_type
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_orders DESC, total_returned_quantity ASC;
