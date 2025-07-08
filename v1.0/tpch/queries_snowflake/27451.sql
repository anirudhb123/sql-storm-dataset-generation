
SELECT 
    COUNT(DISTINCT p.p_partkey) AS distinct_part_count,
    AVG(s.s_acctbal) AS average_supplier_balance,
    LISTAGG(DISTINCT CONCAT(n.n_name, ': ', s.s_name), ', ') WITHIN GROUP (ORDER BY n.n_name) AS supplier_nations
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 50.00
    AND s.s_comment LIKE '%reliable%'
    AND n.n_name IN ('USA', 'Germany', 'Japan')
GROUP BY 
    p.p_name, p.p_partkey, s.s_acctbal, s.s_suppkey, n.n_name
HAVING 
    COUNT(s.s_suppkey) > 2
ORDER BY 
    average_supplier_balance DESC;
