SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 25
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_available_quantity DESC;
