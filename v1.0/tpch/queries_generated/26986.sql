SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' can supply ', p.p_name) AS supplier_info,
    COUNT(DISTINCT ps.ps_supplycost) AS unique_supply_costs,
    AVG(ps.ps_availqty) AS average_availability,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    STRING_AGG(DISTINCT p.p_mfgr, ', ') AS manufacturers
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
GROUP BY 
    s.s_name, n.n_name, p.p_name
HAVING 
    AVG(ps.ps_availqty) > 50
ORDER BY 
    total_returned_quantity DESC
LIMIT 10;
