
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_qty, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    LISTAGG(DISTINCT s.s_name, '; ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names,
    RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
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
    p.p_name LIKE '%widget%'
    AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_qty DESC
LIMIT 10;
