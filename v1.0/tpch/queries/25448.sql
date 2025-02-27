SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END) AS total_revenue,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE 'Europe%' AND
    o.o_orderdate BETWEEN '1996-01-01' AND '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC
LIMIT 100;