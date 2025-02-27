SELECT 
    p.p_name, 
    p.p_mfgr, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_name LIKE '%steel%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_avail_qty DESC, 
    p.p_name;
