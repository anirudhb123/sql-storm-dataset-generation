
SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_returnflag = 'N' 
    AND l.l_linestatus = 'O'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
