SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS full_address,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
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
    p.p_name LIKE '%rubber%'
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    s.s_name, p.p_name, s.s_address, n.n_name, r.r_name
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 100;