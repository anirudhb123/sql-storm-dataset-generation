SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS product_details,
    REPLACE(SUBSTRING(p.p_comment, 1, 20), ' ', '-') AS abbreviated_comment,
    r.r_name AS region_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(s.s_name, '; ') AS supplier_names
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
    p.p_retailprice > 100
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, r.r_name, p.p_comment
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
