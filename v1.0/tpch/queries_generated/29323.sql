SELECT 
    p.p_mfgr,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CASE 
        WHEN AVG(ps.ps_supplycost) < 100 THEN 'Low Cost'
        WHEN AVG(ps.ps_supplycost) BETWEEN 100 AND 500 THEN 'Medium Cost'
        ELSE 'High Cost'
    END AS cost_category
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
    r.r_name = 'ASIA'
GROUP BY 
    p.p_mfgr
ORDER BY 
    supplier_count DESC, 
    avg_supply_cost ASC;
