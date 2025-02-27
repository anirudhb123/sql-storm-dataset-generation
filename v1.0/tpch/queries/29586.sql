SELECT 
    s.s_name AS supplier_name,
    s.s_nationkey,
    n.n_name AS nation_name,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(LENGTH(s.s_comment)) AS max_comment_length
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name LIKE 'A%' 
    AND p.p_comment NOT LIKE '%obsolete%'
GROUP BY 
    s.s_name, s.s_nationkey, n.n_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_supply_cost DESC;
