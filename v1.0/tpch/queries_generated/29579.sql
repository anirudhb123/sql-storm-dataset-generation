SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_comment LIKE '%special%' 
    AND s.s_comment NOT LIKE '%excluded%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_available_quantity DESC, 
    avg_supply_cost ASC;
