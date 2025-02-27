
SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names, 
    p.p_retailprice * SUM(ps.ps_availqty) AS total_retail_value
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
    p.p_name LIKE 'widget%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, p.p_retailprice
ORDER BY 
    total_retail_value DESC
LIMIT 10;
