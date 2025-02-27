SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT SUBSTRING(s.s_name, 1, 10), ', ') AS supplier_names,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_mktsegment AS market_segment
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
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name, r.r_name, n.n_name, c.c_mktsegment
ORDER BY 
    total_available_quantity DESC;
