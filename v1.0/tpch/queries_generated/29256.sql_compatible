
SELECT 
    p.p_name, 
    p.p_mfgr, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ', Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS description,
    COUNT(l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_name, p.p_mfgr, s.s_name, p.p_type
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    revenue DESC;
