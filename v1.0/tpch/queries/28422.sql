SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(o.o_totalprice) AS average_order_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
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
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_available_quantity DESC, average_order_price ASC;