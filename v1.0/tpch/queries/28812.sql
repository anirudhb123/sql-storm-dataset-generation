SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CASE 
        WHEN p.p_size BETWEEN 1 AND 5 THEN 'Small'
        WHEN p.p_size BETWEEN 6 AND 10 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_name, 
    CASE 
        WHEN p.p_size BETWEEN 1 AND 5 THEN 'Small'
        WHEN p.p_size BETWEEN 6 AND 10 THEN 'Medium'
        ELSE 'Large'
    END
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    average_supplier_account_balance DESC;
