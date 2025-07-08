SELECT 
    LOWER(CONCAT('Supplier: ', s.s_name, ' | Part Name: ', p.p_name, ' | Retail Price: ', CAST(p.p_retailprice AS CHAR))) AS info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    AND p.p_type LIKE 'rubber%'
ORDER BY 
    LENGTH(s.s_name), 
    p.p_retailprice DESC
LIMIT 50;
