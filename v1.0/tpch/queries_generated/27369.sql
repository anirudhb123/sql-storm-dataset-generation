SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    CASE 
        WHEN SUM(ps.ps_supplycost) > 10000 THEN 'High Cost'
        WHEN SUM(ps.ps_supplycost) BETWEEN 5000 AND 10000 THEN 'Medium Cost'
        ELSE 'Low Cost'
    END AS cost_category,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
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
    p.p_comment LIKE '%soft%'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC;
