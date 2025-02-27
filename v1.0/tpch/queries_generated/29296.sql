SELECT 
    CONCAT(s.s_name, ' - ', r.r_name) AS supplier_region,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 1000 AND AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    total_parts DESC, avg_supply_cost ASC;
