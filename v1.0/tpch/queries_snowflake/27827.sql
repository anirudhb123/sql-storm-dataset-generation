
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    LISTAGG(DISTINCT ps.ps_comment, '; ') WITHIN GROUP (ORDER BY ps.ps_comment) AS supply_comments
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
    p.p_size IN (12, 24)
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name, r.r_name, n.n_name
ORDER BY 
    supplier_count DESC, avg_supplier_acctbal DESC;
