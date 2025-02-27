SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Part: ', p.p_name, ' (', p.p_partkey, ')') AS descriptive_name,
    TRIM(p.p_brand) AS adjusted_brand
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
    r.r_name = 'ASIA' 
    AND LOWER(p.p_type) LIKE '%metal%'
    AND p.p_retailprice BETWEEN 10.00 AND 500.00
GROUP BY 
    p.p_name, p.p_partkey, p.p_comment, p.p_brand
ORDER BY 
    total_available_qty DESC, average_supply_cost ASC
LIMIT 100;
