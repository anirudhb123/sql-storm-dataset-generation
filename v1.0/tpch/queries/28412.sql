SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty, 
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1 AND 
    AVG(ps.ps_supplycost) < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
ORDER BY 
    total_returned_qty DESC, avg_supply_cost ASC;
