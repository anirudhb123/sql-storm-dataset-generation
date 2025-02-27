SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, short_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;