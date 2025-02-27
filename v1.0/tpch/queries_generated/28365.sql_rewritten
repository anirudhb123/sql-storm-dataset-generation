SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS average_price, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supply
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
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1998-01-01' 
    AND p.p_size > 10 
GROUP BY 
    s.s_name, p.p_name 
HAVING 
    SUM(l.l_quantity) > 500 
ORDER BY 
    total_quantity DESC, average_price ASC;