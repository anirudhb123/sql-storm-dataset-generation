SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_name,
    LEFT(s.s_address, 20) AS short_address, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey AND l.l_partkey = p.p_partkey
GROUP BY 
    p.p_name, 
    s.s_name, 
    short_address
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_available_quantity DESC, 
    average_account_balance DESC;
