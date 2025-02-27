SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_available_quantity DESC
LIMIT 50;
