SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    AVG(o.o_totalprice) AS average_order_value, 
    MAX(o.o_orderdate) AS last_order_date,
    SUM(l.l_quantity) AS total_quantity_sold,
    string_agg(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_contacts
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
WHERE 
    p.p_retailprice > 20.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_orders DESC, average_order_value DESC;