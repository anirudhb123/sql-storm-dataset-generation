SELECT 
    p.p_name, 
    s.s_name, 
    s.s_address, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;