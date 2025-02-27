SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(l.l_quantity) AS total_quantity_ordered,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS has_returns
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
    p.p_comment LIKE '%fragile%'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity_ordered DESC;
