SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS first_five_words,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100)
    AND s.s_name LIKE '%Supplier%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type
ORDER BY 
    average_supplier_balance DESC, comment_length DESC;
