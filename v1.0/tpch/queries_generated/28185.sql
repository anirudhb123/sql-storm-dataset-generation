SELECT 
    p.p_name,
    p.p_mfgr,
    CONCAT('Part: ', p.p_name, ', Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS description,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CASE 
        WHEN AVG(l.l_discount) > 0 THEN 'Discounted' 
        ELSE 'Not Discounted' 
    END AS discount_status
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 1000
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_type, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
