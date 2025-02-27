
SELECT 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions,
    LEFT(p.p_comment, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 20 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    avg_price DESC;
