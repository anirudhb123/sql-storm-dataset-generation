SELECT 
    CONCAT(s_name, ' from ', r_name) AS supplier_region,
    p_type,
    SUM(ps_supplycost * ps_availqty) AS total_cost,
    COUNT(*) AS total_suppliers,
    STRING_AGG(DISTINCT p_name, ', ') AS product_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_comment LIKE '%special%'
GROUP BY 
    s_name, r_name, p_type
HAVING 
    SUM(ps_supplycost * ps_availqty) > 10000
ORDER BY 
    total_cost DESC;
