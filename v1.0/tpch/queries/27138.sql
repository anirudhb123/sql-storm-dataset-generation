
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    p.p_comment LIKE '%special%'
GROUP BY 
    SUBSTRING(p.p_name, 1, 10), r.r_name
ORDER BY 
    customer_count DESC, avg_supply_cost ASC
LIMIT 50;
