
SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS comments_summary
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
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_size > 10
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
