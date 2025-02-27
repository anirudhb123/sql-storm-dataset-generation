SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(s.s_acctbal) AS max_supplier_balance,
    MIN(s.s_acctbal) AS min_supplier_balance,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    CONCAT('Available part: ', p.p_name, ' from suppliers: ', STRING_AGG(DISTINCT s.s_name, ', ')) AS part_supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%plastic%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
