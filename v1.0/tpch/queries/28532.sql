
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    COUNT(o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS comments,
    LENGTH(p.p_comment) AS part_comment_length
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
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, LENGTH(p.p_comment)
ORDER BY 
    total_revenue DESC, part_name ASC
LIMIT 10;
