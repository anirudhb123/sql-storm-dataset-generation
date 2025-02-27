
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.r_name AS region_name
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%BRASS%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND o.o_orderstatus = 'F'
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_orders DESC, avg_extended_price DESC;
