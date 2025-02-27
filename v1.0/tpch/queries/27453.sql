SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') AS part_names
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_comment LIKE '%special%'
    AND s.s_comment NOT LIKE '%outdated%'
    AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    region_name;
