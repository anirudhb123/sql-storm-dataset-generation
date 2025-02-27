SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(l.l_quantity) AS avg_quantity, 
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
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
WHERE 
    p.p_type LIKE '%brass%' 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_revenue DESC, 
    avg_quantity DESC;