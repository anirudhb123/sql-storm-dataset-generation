SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    o.o_orderstatus,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND p.p_brand LIKE 'Brand%'
    AND c.c_mktsegment = 'SEGMENT_A'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderstatus
ORDER BY 
    total_revenue DESC
LIMIT 100;