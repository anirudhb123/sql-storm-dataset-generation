SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS num_parts,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_part_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CONCAT('Supplier ', s.s_name, ' from ', n.n_name, ' supplies ', COUNT(DISTINCT ps.ps_partkey), ' parts.') AS supplier_info
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_regionkey IN (
        SELECT r.r_regionkey 
        FROM region r 
        WHERE r.r_name LIKE 'S%'
    )
GROUP BY 
    s.s_name, n.n_name
HAVING 
    SUM(ps.ps_supplycost) > 1000
ORDER BY 
    total_supply_cost DESC;
