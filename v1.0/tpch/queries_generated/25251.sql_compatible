
SELECT 
    CONCAT(p.p_name, ' - ', s.s_name) AS part_supplier,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT('OrderID:', o.o_orderkey, ' Date:', o.o_orderdate), '; ') AS orders_info
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND s.s_acctbal > 500.00 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, p.p_partkey, s.s_suppkey
HAVING 
    SUM(l.l_discount) > 100
ORDER BY 
    total_quantity DESC
LIMIT 10;
