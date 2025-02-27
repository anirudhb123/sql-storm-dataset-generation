SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(p.p_retailprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_size > 10) AS large_parts 
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
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'S%')
GROUP BY 
    supplier_info
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC;
