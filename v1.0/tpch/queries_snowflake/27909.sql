
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_account_balance,
    LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    SUBSTRING(p.p_name, 1, 10)
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_account_balance DESC;
