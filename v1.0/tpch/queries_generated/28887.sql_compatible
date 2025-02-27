
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served,
    LENGTH(s.s_comment) AS supplier_comment_length
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, p.p_name, s.s_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_supply_cost DESC, total_available_quantity DESC;
