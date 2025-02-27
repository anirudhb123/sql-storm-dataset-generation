SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ': ', c.c_comment), '; ') AS cust_comments,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
    s.s_comment LIKE '%quality%'
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_extended_price ASC
LIMIT 50;