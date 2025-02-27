SELECT 
    p.p_type, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE l.l_extendedprice 
        END) AS total_revenue,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions
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
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    AND p.p_size BETWEEN 10 AND 30
GROUP BY 
    p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_revenue DESC;