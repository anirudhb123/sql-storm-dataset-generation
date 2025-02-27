
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_type LIKE '%brass%' 
    AND p.p_retailprice > 100.00
GROUP BY 
    p.p_name, 
    p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_supply_cost DESC;
