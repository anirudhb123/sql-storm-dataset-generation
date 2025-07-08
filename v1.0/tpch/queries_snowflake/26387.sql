
SELECT 
    p.p_name,
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_details,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    LISTAGG(DISTINCT s.s_comment, '; ') WITHIN GROUP (ORDER BY s.s_comment) AS supplier_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_brand LIKE 'Brand%'
GROUP BY 
    p.p_name, supplier_details
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
