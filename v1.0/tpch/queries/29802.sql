SELECT 
    p.p_brand,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', s.s_name, s.s_phone), '; ') AS supplier_info,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_type LIKE '%metal%'
    AND p.p_name ILIKE '%gadget%'
GROUP BY 
    p.p_brand
ORDER BY 
    unique_parts DESC, total_available_quantity DESC
LIMIT 10;
