
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    AVG(l.l_discount) AS avg_discount, 
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    s.s_comment LIKE '%fragile%' AND 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 50 AND 
    AVG(l.l_discount) < 0.1
ORDER BY 
    total_revenue DESC, p.p_name;
