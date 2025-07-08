
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT ps.ps_partkey) AS part_supply_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    LISTAGG(DISTINCT SUBSTRING(s.s_comment, 1, 15), '; ') WITHIN GROUP (ORDER BY s.s_comment) AS unique_comments,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
GROUP BY 
    s.s_name, p.p_name, p.p_partkey
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    total_supply_cost DESC, supplier_name ASC;
