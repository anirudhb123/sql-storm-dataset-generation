
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    MAX(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END) AS max_account_balance,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', p.p_type), ', ') AS part_details,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))) AS total_customers_in_asia 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    p.p_partkey, p.p_name 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    average_supply_cost DESC 
LIMIT 10;
