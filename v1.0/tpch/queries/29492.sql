SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(CASE 
        WHEN LENGTH(p.p_comment) > 10 THEN SUBSTRING(p.p_comment FROM 1 FOR 10) || '...' 
        ELSE p.p_comment END) AS truncated_comment,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regional_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size > 20
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    total_available_quantity DESC
LIMIT 50;
