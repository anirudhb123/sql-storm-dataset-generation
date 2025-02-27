
SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customers,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING(p.p_comment, 1, 10) AS comment_preview
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
    p.p_retailprice > 50.00 
    AND l.l_shipdate >= DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    total_sales DESC, comment_length ASC;
