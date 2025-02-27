SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    STRFTIME('%Y-%m', o.o_orderdate) AS order_month
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
    s.s_acctbal > 500.00 
AND 
    l.l_returnflag = 'N' 
GROUP BY 
    p.p_name, 
    s.s_name, 
    order_month
HAVING 
    total_orders > 10 
ORDER BY 
    order_month DESC, 
    total_quantity DESC;
