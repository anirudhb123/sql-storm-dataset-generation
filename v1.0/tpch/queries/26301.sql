SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_returned_quantity,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', n.n_comment), '; ') AS nation_comments
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_size > 10
GROUP BY 
    s.s_name, p.p_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;