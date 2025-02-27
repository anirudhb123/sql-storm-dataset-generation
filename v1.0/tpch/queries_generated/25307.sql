SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_address, ') - ', 
           CASE 
               WHEN s_acctbal > 10000 THEN 'High Value' 
               WHEN s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value' 
               ELSE 'Low Value' 
           END) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    GROUP_CONCAT(DISTINCT p.p_name ORDER BY p.p_name SEPARATOR ', ') AS part_names,
    r.r_name AS region_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.s_comment NOT LIKE '%reliable%'
    AND p.p_retailprice < 500
GROUP BY 
    s.s_suppkey, region_name
HAVING 
    total_parts > 5
ORDER BY 
    total_supply_cost DESC;
