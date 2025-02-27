SELECT 
    CONCAT('Part Name: ', p_name, ', Part Type: ', p_type, ', Brand: ', p_brand, ', Price: $', FORMAT(p_retailprice, 2)) AS part_details,
    LEFT(s_name, 15) AS supplier_name,
    SUBSTRING_INDEX(s_address, ' ', 3) AS supplier_location,
    COUNT(DISTINCT o_orderkey) AS total_orders
FROM 
    part
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE 
    p_size > 10 AND 
    orders.o_orderdate BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
GROUP BY 
    part.p_partkey, s_name
ORDER BY 
    total_orders DESC
LIMIT 10;
