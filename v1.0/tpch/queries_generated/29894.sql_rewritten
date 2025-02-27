SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS average_part_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS region_names
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
    p.p_size > 20 
AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name 
ORDER BY 
    total_revenue DESC, unique_customers ASC;