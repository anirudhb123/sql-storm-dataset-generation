SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(CASE WHEN s.s_acctbal < 1000 THEN 'Low Balance' ELSE 'Sufficient Balance' END) AS balance_category,
    GROUP_CONCAT(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')') ORDER BY s.s_name SEPARATOR ', ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%Steel%'
    AND r.r_name IN ('Asia', 'Europe')
GROUP BY 
    p.p_partkey
HAVING 
    total_available_quantity > 500
ORDER BY 
    supplier_count DESC, p.p_name;
