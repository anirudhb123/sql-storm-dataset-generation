SELECT 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    STRING_AGG(DISTINCT p.p_type, ', ') AS part_types,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
WHERE 
    l.l_returnflag = 'N' 
    AND l.l_linestatus = 'O'
GROUP BY 
    s.s_name, n.n_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
