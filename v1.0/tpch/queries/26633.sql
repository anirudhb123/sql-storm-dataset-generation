
SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS avg_returned_revenue,
    STRING_AGG(DISTINCT p.p_comment, ', ') AS unique_comments
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
