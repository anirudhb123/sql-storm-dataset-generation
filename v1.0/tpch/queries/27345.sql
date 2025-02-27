SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT SUBSTRING(s.s_comment, 1, 20), '; ') AS supplier_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_name LIKE '%steel%'
    AND s.s_comment IS NOT NULL
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    avg_supply_cost DESC;
