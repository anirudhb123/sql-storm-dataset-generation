SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    CONCAT(SUBSTRING(p.p_comment, 1, 10), '...') AS truncated_comment,
    UPPER(p.p_mfgr) AS uppercase_mfgr,
    LENGTH(p.p_name) AS name_length,
    (SELECT COUNT(*) FROM nation n WHERE n.n_nationkey = s.s_nationkey) AS nation_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment, p.p_mfgr
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
