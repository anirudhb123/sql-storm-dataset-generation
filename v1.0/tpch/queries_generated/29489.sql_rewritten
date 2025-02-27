SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_involved,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_involved
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%important%' 
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_available_quantity DESC, 
    total_orders DESC;