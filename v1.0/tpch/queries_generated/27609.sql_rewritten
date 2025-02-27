SELECT 
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    p.p_name AS part_name,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_quantity) AS min_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
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
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31' 
GROUP BY 
    s.s_name, c.c_name, p.p_name 
HAVING 
    COUNT(l.l_orderkey) > 10 
ORDER BY 
    total_revenue DESC, avg_discount ASC;