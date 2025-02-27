SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(p.p_retailprice) AS average_price, 
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%soft%' 
    AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2 
        WHERE s2.s_comment LIKE '%excellent%'
    )
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    average_price DESC;
