SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Total Suppliers: ', COUNT(DISTINCT ps.ps_suppkey)) AS supplier_info,
    UPPER(p.p_brand) AS upper_case_brand,
    CONCAT('Available: ', CAST(SUM(ps.ps_availqty) AS CHAR)) AS availability_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name LIKE '%United%'
GROUP BY 
    p.p_name, p.p_brand, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
