SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_quantity ELSE 0 END) AS total_discounted_quantity, 
    MAX(CASE WHEN o.o_orderdate > '1997-01-01' THEN o.o_totalprice ELSE NULL END) AS max_recent_order_value,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_type LIKE '%raw%'
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5 
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;