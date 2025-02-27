SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(p.p_container) AS most_common_container,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT s.s_name, '; ') AS suppliers_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size IN (10, 20, 30)
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 5
ORDER BY 
    avg_retail_price DESC, 
    supplier_count DESC;
