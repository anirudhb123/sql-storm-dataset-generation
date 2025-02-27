SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ' ', p.p_container, ')'), '; ') AS part_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 1000.00
    AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_available_quantity DESC;
