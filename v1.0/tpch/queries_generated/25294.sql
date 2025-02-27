SELECT 
    CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    PARTITION BY n.n_name
FROM 
    supplier s 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    AND p.p_comment LIKE '%special%' 
    AND LENGTH(n.n_name) < 10
ORDER BY 
    p.p_retailprice DESC,
    s.s_name
LIMIT 100;
