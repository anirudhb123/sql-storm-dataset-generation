SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN LENGTH(p.p_comment) > 20 THEN 1 ELSE 0 
    END) AS long_comments,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    GROUP_CONCAT(DISTINCT CONCAT(n.n_name, ': ', s.s_name) ORDER BY s.s_name) AS supplier_nations
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    avg_supply_cost DESC;
