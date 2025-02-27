SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_availability, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
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
WHERE 
    p.p_type LIKE '%brass%'
    AND n.n_name NOT IN ('ALGERIA', 'CANADA', 'EGYPT')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_availability DESC
LIMIT 10;
