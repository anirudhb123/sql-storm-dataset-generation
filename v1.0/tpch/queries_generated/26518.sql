SELECT 
    p.p_brand, 
    COUNT(*) AS total_parts, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(p.p_retailprice) AS average_retail_price,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_provided
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_brand
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_parts DESC, 
    average_retail_price ASC;
