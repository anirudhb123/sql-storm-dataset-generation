
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_balance,
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_details,
    r.r_name AS region_name
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
    p.p_type LIKE '%widget%' 
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, r.r_name
ORDER BY 
    total_available_quantity DESC, part_name
LIMIT 10;
