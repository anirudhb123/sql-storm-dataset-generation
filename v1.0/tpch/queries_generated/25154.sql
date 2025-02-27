SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(s.s_acctbal) AS average_supplier_account_balance, 
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_provided
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    p.p_type LIKE '%metal%'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC;
