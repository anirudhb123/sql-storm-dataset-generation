SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_modes,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name, c.c_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
