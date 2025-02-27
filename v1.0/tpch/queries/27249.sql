SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    LEFT(p.p_comment, 20) AS short_comment,
    CONCAT('Total Suppliers: ', COUNT(DISTINCT ps.ps_suppkey), ' | Total Qty: ', SUM(ps.ps_availqty)) AS summary_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%brass%'
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
