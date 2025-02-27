SELECT
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT c.c_mktsegment, '; ') AS market_segments,
    (SELECT COUNT(*) 
     FROM lineitem l 
     WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0) AS discount_sales,
    CASE 
        WHEN AVG(o.o_totalprice) > 1000 THEN 'High Value'
        WHEN AVG(o.o_totalprice) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey)
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size >= 12
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_available_quantity DESC, total_orders DESC
LIMIT 100;
