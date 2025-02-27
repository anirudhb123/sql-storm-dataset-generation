SELECT 
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    ARRAY_AGG(DISTINCT CONCAT('OrderID:', o.o_orderkey, ' Date:', o.o_orderdate, ' Status:', o.o_orderstatus)) AS order_details
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100.00
    AND o.o_orderstatus = 'F'
GROUP BY 
    p.p_brand, p.p_type
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    avg_price DESC, supplier_count DESC;
