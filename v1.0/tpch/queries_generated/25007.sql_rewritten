SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS num_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_cost,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    s.s_name, n.n_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_cost DESC;