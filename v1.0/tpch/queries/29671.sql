SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT SUBSTRING(p.p_comment, 1, 10), '; ') AS part_comments
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
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_quantity DESC
LIMIT 10;