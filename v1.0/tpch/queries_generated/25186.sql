SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_type,
    p.p_brand,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(s.s_name, ', ') AS supplier_names,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
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
    p.p_type LIKE '%brass%'
    AND r.r_name IN ('AMERICA', 'EUROPE')
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, p.p_mfgr, p.p_type, p.p_brand
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 2
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
