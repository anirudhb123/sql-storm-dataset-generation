SELECT 
    CONCAT('Supplier:', s.s_name, ' (', s.s_suppkey, ') - ', 
           'Part:', p.p_name, ' (', p.p_partkey, ') - ', 
           'Total Supply Cost: $', FORMAT(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost, 
           ' - ', 
           'Comment:', ps.ps_comment) AS supply_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(p.p_comment) > 10 
    AND s.s_acctbal > 1000
GROUP BY 
    s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_comment
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
