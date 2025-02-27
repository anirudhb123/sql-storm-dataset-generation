SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS product_info,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT concat(c.c_name, ' from ', s.s_name), '; ') AS customers_and_suppliers
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-12-31' 
    AND p.p_mfgr LIKE 'Manufacture%'
GROUP BY 
    p.p_name, p.p_mfgr, p.p_brand
ORDER BY 
    total_returned DESC, avg_price_after_discount ASC
LIMIT 100;