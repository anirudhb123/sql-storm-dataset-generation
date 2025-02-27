SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT n.n_name ORDER BY n.n_name SEPARATOR ', '), ', ', 5) AS top_nations,
    TRIM(SUBSTRING(p.p_comment, 1, 15)) AS short_comment
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
WHERE 
    p.p_retailprice > 50.00
    AND n.n_regionkey IN (
        SELECT r.r_regionkey 
        FROM region r 
        WHERE r.r_name LIKE 'Asia%'
    )
GROUP BY 
    p.p_partkey
HAVING 
    total_revenue > 100000
ORDER BY 
    total_revenue DESC;
