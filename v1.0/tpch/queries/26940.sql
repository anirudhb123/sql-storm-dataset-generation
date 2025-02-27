SELECT 
    p.p_name,
    p.p_brand,
    CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    SUM(ps.ps_availqty) AS total_availqty,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT CONCAT('Customer: ', c.c_name, ', Segment: ', c.c_mktsegment), '; ') AS customer_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, s.s_address
ORDER BY 
    total_availqty DESC, avg_order_value DESC
LIMIT 10;