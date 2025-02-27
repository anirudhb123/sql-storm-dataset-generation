SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    n.n_name AS supplier_nation,
    r.r_name AS supplier_region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT p.p_comment, ', ') AS comments
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
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10 
    AND l.l_shipdate > '2023-01-01' 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, c.c_name, n.n_name, r.r_name
ORDER BY 
    total_quantity DESC
LIMIT 100;
