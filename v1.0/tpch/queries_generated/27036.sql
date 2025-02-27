SELECT 
    CONCAT('Supplier: ', s.s_name, ' (Key: ', s.s_suppkey, ') - Address: ', s.s_address, 
           ' - Phone: ', s.s_phone, ' - Balance: $', FORMAT(s.s_acctbal, 2), 
           CASE 
               WHEN s.s_acctbal > 10000 THEN ' - Status: Premium'
               WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN ' - Status: Standard'
               ELSE ' - Status: Basic'
           END) AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supply,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
    GROUP_CONCAT(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')') ORDER BY p.p_name ASC SEPARATOR ', ') AS supplied_parts
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal
HAVING 
    total_parts_supply > 0 
ORDER BY 
    total_supply_value DESC;
