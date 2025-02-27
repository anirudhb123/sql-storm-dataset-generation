SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_comment), '; ') AS national_supplier_comments
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
    AND p.p_type LIKE '%soft%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
ORDER BY 
    total_sales DESC, order_count DESC
LIMIT 10;