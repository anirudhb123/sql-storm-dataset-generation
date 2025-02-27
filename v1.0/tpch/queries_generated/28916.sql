SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_comment, ' ', 3), ' ', -3) AS supplier_comment_excerpt
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%Asia%' 
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, r.r_name
HAVING 
    total_quantity > 100
ORDER BY 
    total_orders DESC, avg_price ASC
LIMIT 10;
