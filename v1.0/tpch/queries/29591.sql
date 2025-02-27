SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    STRING_AGG(DISTINCT CONCAT(o.o_orderstatus, ': ', o.o_orderpriority), '; ') AS order_statuses
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%steel%' AND 
    n.n_name IN (SELECT r_name FROM region WHERE r_regionkey > 0)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    order_count DESC, p.p_name;
