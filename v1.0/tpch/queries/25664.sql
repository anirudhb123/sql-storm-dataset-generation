SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(CASE 
            WHEN LENGTH(s.s_comment) > 50 THEN LENGTH(s.s_comment) 
            ELSE NULL 
        END) AS avg_comment_length,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
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
    s.s_acctbal > 1000.00 
    AND p.p_size BETWEEN 10 AND 30 
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 50
ORDER BY 
    total_available_quantity DESC;