SELECT 
    s.s_name AS supplier_name,
    count(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
    STRING_AGG(DISTINCT p.p_name || ' (' || p.p_container || ')', ', ') AS supplied_parts_list
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_returnflag = 'N' 
    AND l.l_linestatus = 'O' 
    AND s.s_comment LIKE '%reliable%'
GROUP BY 
    s.s_suppkey, s.s_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_supply_cost DESC;
