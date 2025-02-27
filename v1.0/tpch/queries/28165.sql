SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_name LIKE '%steel%'
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    average_price DESC;
