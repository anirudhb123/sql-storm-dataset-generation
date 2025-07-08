
SELECT 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_quantity,
    AVG(ps.ps_supplycost) AS average_cost,
    LISTAGG(DISTINCT p.p_type, ', ') WITHIN GROUP (ORDER BY p.p_type) AS part_types,
    CASE 
        WHEN AVG(ps.ps_supplycost) > 100 THEN 'Expensive Supplies'
        ELSE 'Affordable Supplies'
    END AS cost_category
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 10
ORDER BY 
    total_quantity DESC
LIMIT 50;
