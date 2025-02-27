SELECT 
    p.p_name, 
    p.p_brand, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    REPLACE(p.p_type, ' ', '-') AS formatted_type,
    CASE 
        WHEN p.p_retailprice > 100.00 THEN 'Premium'
        WHEN p.p_retailprice BETWEEN 50.00 AND 100.00 THEN 'Standard'
        ELSE 'Budget'
    END AS price_category,
    CONCAT('Supplier count for ', p.p_name, ' is ', COUNT(DISTINCT ps.s_suppkey)) AS supplier_info
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
    p.p_size BETWEEN 1 AND 50
AND 
    r.r_name LIKE '%Americas%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_comment, p.p_type, p.p_retailprice
ORDER BY 
    total_available_quantity DESC, avg_supply_cost ASC
LIMIT 20;
