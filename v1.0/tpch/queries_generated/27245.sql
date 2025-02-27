SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s_name) AS supplier_count,
    AVG(l_extendedprice * (1 - l_discount)) AS avg_price_after_discount,
    GROUP_CONCAT(DISTINCT CONCAT('Type: ', p_type, ' | Brand: ', p_brand) ORDER BY p_type) AS type_brand_summary
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    lineitem ON ps_partkey = l_partkey
WHERE 
    p_size BETWEEN 10 AND 20 
    AND l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    short_name
HAVING 
    supplier_count > 5 
ORDER BY 
    avg_price_after_discount DESC
LIMIT 10;
