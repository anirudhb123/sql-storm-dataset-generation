SELECT 
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_order_value,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ': ', l.l_quantity), ', ') AS products_sold
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
    s.s_acctbal > 5000.00 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    s.s_name 
ORDER BY 
    total_orders DESC, average_order_value DESC 
LIMIT 10;