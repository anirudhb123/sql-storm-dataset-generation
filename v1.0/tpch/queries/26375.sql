
SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    CONCAT('Total Orders: ', COUNT(DISTINCT o.o_orderkey)) AS order_summary,
    LEFT(s.s_comment, 50) || '...' AS supplier_comment_snippet
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, s.s_comment
ORDER BY 
    total_quantity DESC, avg_price ASC;
