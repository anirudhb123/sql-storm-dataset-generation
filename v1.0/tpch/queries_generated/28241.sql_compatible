
SELECT 
    p.p_name AS part_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(LENGTH(p.p_comment)) AS max_comment_length,
    STRING_AGG(s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC
LIMIT 50;
