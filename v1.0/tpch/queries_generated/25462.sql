SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    CONCAT('Supplier ', s.s_name, ' from ', n.n_name, ' supplies the part ', p.p_name) AS description,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10 AND 
    s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 50;
