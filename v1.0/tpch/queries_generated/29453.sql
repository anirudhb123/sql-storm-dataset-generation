SELECT 
    SUBSTRING(p_name, 1, 10) AS short_part_name,
    COUNT(DISTINCT s_name) AS unique_suppliers,
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
    AVG(l_discount) AS average_discount_rate,
    REPLACE(n_name, ' ', '_') AS formatted_nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    short_part_name, formatted_nation_name
HAVING 
    total_supply_cost > 10000
ORDER BY 
    average_discount_rate DESC, unique_suppliers ASC;
