SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
    p.p_type LIKE '%brass%' AND
    o.o_orderstatus IN ('O', 'P') AND 
    s.s_acctbal > 100.00
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000.00
ORDER BY 
    total_quantity DESC, last_order_date DESC;
