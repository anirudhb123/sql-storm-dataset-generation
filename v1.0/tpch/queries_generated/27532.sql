SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    CONCAT('Part: ', p.p_name, ', Supplier Count: ', COUNT(DISTINCT ps.ps_suppkey), ', Avg Cost: $', ROUND(AVG(ps.ps_supplycost), 2)) AS summary
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, average_supply_cost ASC
LIMIT 10;
