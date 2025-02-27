SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
