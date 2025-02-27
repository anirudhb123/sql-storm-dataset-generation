SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available,
    MAX(o.o_totalprice) AS max_order_value,
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
    p.p_retailprice > 50.00
    AND s.s_acctbal >= 1000.00
    AND l.l_shipmode LIKE 'AIR%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_available DESC;
