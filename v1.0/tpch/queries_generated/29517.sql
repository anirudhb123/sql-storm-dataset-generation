SELECT 
    SUBSTRING(p.p_name, 1, 20) AS truncated_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    CASE 
        WHEN SUM(l.l_extendedprice) > 100000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS order_value_category
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem AS l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, truncated_name
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_available_quantity DESC, average_account_balance DESC
LIMIT 10;
