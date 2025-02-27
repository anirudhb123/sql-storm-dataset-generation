SELECT 
    p.p_name,
    COUNT(ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_supplier_balance,
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
    p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    COUNT(ps.ps_suppkey) > 5
ORDER BY 
    average_supplier_balance DESC, supplier_count DESC;
