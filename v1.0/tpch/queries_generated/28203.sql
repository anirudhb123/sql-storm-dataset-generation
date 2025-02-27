SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.r_name AS region_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%fragile%'
GROUP BY 
    s.s_name, p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_available_quantity DESC, average_supplier_account_balance DESC;
