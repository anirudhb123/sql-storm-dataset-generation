SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_type,
    p.p_size,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(CASE WHEN s.s_nationkey = n.n_nationkey THEN s.s_acctbal ELSE NULL END) AS max_supplier_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', ' ') AS cleaned_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_type, p.p_size
ORDER BY 
    total_available_quantity DESC, avg_supply_cost ASC;
