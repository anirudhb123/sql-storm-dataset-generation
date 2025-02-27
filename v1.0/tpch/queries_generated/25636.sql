SELECT 
    CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
