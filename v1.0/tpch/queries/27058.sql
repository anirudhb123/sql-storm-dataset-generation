SELECT 
    CONCAT(c.c_name, ' from ', n.n_name) AS customer_info,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_name LIKE 'A%' 
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    customer_info, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;