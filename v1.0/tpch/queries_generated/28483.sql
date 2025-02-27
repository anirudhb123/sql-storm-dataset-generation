SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name, 
           ' | Address: ', s.s_address, ' | Phone: ', s.s_phone) AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    SUM(ps.ps_availqty) AS total_avail_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT('Part: ', p.p_name, ' | Price: ', p.p_retailprice), '; ') AS part_details
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
GROUP BY 
    s.s_suppkey, n.n_nationkey
ORDER BY 
    total_parts DESC, avg_supply_cost ASC
LIMIT 10;
