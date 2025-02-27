SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CONCAT('Product: ', p.p_name, ', Average Price: ', ROUND(AVG(p.p_retailprice), 2)) AS product_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size = (SELECT MAX(p_inner.p_size) FROM part p_inner)
GROUP BY 
    p.p_name
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
