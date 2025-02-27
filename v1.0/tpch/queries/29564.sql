SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_returned_quantity,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' - ', r.r_name), '; ') AS nation_region_info
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
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;
