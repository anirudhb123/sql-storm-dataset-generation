SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' - ', LEFT(s.s_address, 20), '...', ' (', n.n_name, ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS unique_comments
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
WHERE 
    n.n_name LIKE 'A%' 
    AND o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_quantity DESC, average_discount ASC
LIMIT 100;