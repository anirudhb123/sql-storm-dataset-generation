SELECT 
    SUBSTRING(p.p_name, 1, 15) AS short_part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', s.s_address), '; ') AS suppliers_info
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
    p.p_retailprice > 100.00
    AND p.p_comment LIKE '%plastic%'
    AND s.s_acctbal > 500.00
GROUP BY 
    r.r_name, SUBSTRING(p.p_name, 1, 15)
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC;
