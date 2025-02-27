
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_discount) AS average_discount, 
    COUNT(DISTINCT o.o_orderkey) AS unique_orders,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_comment), '; ') AS supplier_comments
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
WHERE 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND p.p_type LIKE '%rubber%'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
