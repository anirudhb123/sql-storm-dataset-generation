SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUBSTRING(p.p_comment FROM 1 FOR 20) || '...' AS short_comment,
    REPLACE(p.p_mfgr, 'INC', 'INCORPORATED') AS modified_manufacturer
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
    r.r_name LIKE '%ASIA%'
    AND p.p_size BETWEEN 1 AND 100
    AND p.p_retailprice < 200.00
GROUP BY 
    p.p_name, p.p_comment, p.p_mfgr
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
