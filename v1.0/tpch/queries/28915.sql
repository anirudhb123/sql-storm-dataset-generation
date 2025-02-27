SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    MAX(ps.ps_supplycost) AS max_supply_cost, 
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
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
WHERE 
    p.p_size > 10 AND 
    o.o_orderstatus = 'O' AND 
    s.s_comment LIKE '%quality%'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    order_count DESC, max_supply_cost DESC;
