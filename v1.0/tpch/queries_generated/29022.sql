SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(l.l_comment, '; ') AS comments
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
    p.p_size > 10
AND 
    s.s_acctbal > 1000
GROUP BY 
    short_name, supplier_info
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_price DESC
LIMIT 50;
