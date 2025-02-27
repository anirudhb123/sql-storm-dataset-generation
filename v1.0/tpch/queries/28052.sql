SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(p.p_retailprice) AS max_part_price,
    MIN(p.p_retailprice) AS min_part_price,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_revenue DESC;
