
SELECT 
    p.p_name AS part_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_size IN (1, 2, 3) 
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, p.p_comment, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_supply_cost DESC;
