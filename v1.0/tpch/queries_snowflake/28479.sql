
SELECT 
    p.p_mfgr,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    LISTAGG(DISTINCT CONCAT(p.p_name, ' (', ps.ps_availqty, ')'), '; ') WITHIN GROUP (ORDER BY p.p_name) AS available_parts,
    LISTAGG(DISTINCT CONCAT(n.n_name, ': ', s.s_name), '; ') WITHIN GROUP (ORDER BY n.n_name) AS supplier_nations
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
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_mfgr
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_supply_cost DESC;
