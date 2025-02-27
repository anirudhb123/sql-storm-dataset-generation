SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT SUBSTRING(s.s_name, 1, 10), ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_comment LIKE '%premium%'
    AND s.s_comment LIKE '%urgent%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_available_qty DESC, 
    avg_retail_price ASC
LIMIT 10;
