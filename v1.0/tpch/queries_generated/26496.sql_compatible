
SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS latest_ship_date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
    s.s_acctbal > 1000.00
    AND l.l_returnflag = 'N'
    AND p.p_type LIKE '%plastic%'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    total_revenue DESC;
