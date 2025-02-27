SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT SUBSTRING(s.s_name FROM 1 FOR 10), ', ') AS supplier_names,
    ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_cost
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
WHERE 
    r.r_name LIKE 'Asia%' 
    AND p.p_comment ILIKE '%quality%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    rank_by_cost
LIMIT 10;
