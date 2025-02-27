SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' is supplying ', p.p_name, ' of type ', p.p_type, ' with a retail price of ', FORMAT(p.p_retailprice, 2), ' and a comment: ', p.p_comment) AS supplier_product_info
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_size BETWEEN 10 AND 30
AND 
    s.s_acctbal > 5000.00
ORDER BY 
    p.p_retailprice DESC
LIMIT 10;
