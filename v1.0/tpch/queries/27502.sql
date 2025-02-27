
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment
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
    r.r_name LIKE 'Asia%' 
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
