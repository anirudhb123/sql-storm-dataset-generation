
SELECT 
    p.p_name,
    s.s_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT SUBSTRING(p.p_comment, 1, 20), ', ') AS partial_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10 AND 
    l.l_shipdate BETWEEN '1996-01-01' AND '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    unique_customers DESC, total_quantity DESC;
