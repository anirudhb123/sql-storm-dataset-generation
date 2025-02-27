SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CASE 
        WHEN AVG(s.s_acctbal) > 1000 THEN 'High Value'
        WHEN AVG(s.s_acctbal) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS supplier_account_value
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%metal%'
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC;
