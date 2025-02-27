SELECT 
    CONCAT('Part: ', p_name, ' | Brand: ', p_brand, ' | Supplier: ', s_name, ' | Price: $', FORMAT(p_retailprice, 2), ' | Comment: ', p_comment) AS detailed_info,
    COUNT(DISTINCT o_orderkey) AS order_count,
    SUM(l_quantity) AS total_quantity,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    part
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    lineitem ON p_partkey = l_partkey
JOIN 
    orders ON l_orderkey = o_orderkey
GROUP BY 
    p_partkey, p_name, s_name, p_brand, p_retailprice, p_comment
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 10;
