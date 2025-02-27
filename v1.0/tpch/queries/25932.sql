
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_avail_qty,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10 AND 
    p.p_brand LIKE 'Brand%'
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    unique_suppliers DESC, 
    p.p_name;
