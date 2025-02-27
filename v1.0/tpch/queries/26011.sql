SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', p.p_comment), '; ') AS product_details,
    r.r_name AS region_name
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
    p.p_size IN (10, 20, 30)
GROUP BY 
    p.p_brand, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    unique_suppliers DESC, avg_supply_cost ASC;
