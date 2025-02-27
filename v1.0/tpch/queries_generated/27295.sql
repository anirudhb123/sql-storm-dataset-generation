SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supported
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
    p.p_size BETWEEN 10 AND 20 
    AND p.p_retailprice > 100.00 
    AND s.s_acctbal > 5000.00
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 5
ORDER BY 
    total_available_qty DESC;
