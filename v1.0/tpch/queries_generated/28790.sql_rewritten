SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    left(s.s_address, 20) AS supplier_address,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
    p.p_size >= 10 
    AND o.o_orderdate >= '1996-01-01'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
ORDER BY 
    total_quantity DESC, avg_revenue DESC
LIMIT 10;