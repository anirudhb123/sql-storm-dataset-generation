SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_sales,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
    p.p_comment LIKE '%fragile%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_extendedprice) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
