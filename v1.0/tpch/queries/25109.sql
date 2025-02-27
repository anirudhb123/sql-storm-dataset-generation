SELECT 
    CONCAT(s_name, ' (', s_address, ') - ', s_phone) AS supplier_details,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    AVG(o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT p_type, ', ') AS types_supplied,
    STRING_AGG(DISTINCT r_name, '; ') AS regions_served
FROM 
    supplier 
JOIN 
    partsupp ON s_suppkey = ps_suppkey
JOIN 
    part ON ps_partkey = p_partkey
JOIN 
    lineitem ON l_partkey = p_partkey
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
JOIN 
    nation ON s_nationkey = n_nationkey
JOIN 
    region ON n_regionkey = r_regionkey
WHERE 
    p_name LIKE '%steel%' 
    AND o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s_name, s_address, s_phone
ORDER BY 
    total_revenue DESC
LIMIT 10;