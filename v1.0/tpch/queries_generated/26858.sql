SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    STRING_AGG(DISTINCT CONCAT_WS(', ', l_shipmode, l_returnflag, l_linestatus), '; ') AS processed_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    YEAR(o.o_orderdate) AS order_year
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
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, YEAR(o.o_orderdate)
ORDER BY 
    total_revenue DESC, order_year DESC
LIMIT 10;
