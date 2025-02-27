SELECT 
    CONCAT(s.s_name, ' (', r.r_name, ')') AS supplier_region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS avg_returned_revenue,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT ps.ps_comment ORDER BY ps.ps_partkey SEPARATOR '; '), '; ', 5) AS sample_comments
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND p.p_size > 10
GROUP BY 
    supplier_region
HAVING 
    total_orders > 5
ORDER BY 
    total_revenue DESC;
