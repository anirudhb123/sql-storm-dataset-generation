SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    MAX(p.p_retailprice) AS max_retail_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS supplier_info,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN p.p_size > 10 THEN 'Large'
        ELSE 'Small'
    END AS size_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%metal%'
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
