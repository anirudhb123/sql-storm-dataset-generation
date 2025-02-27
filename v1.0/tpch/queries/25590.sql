SELECT 
    p.p_name,
    p.p_brand,
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
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
    p.p_type LIKE '%metal%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, n.n_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC, avg_retail_price ASC;
