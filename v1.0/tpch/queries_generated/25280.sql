SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_price,
    STRING_AGG(DISTINCT CONCAT(CAST(o.o_orderdate AS VARCHAR), ' - ', o.o_orderstatus), '; ') AS order_status_summary,
    CONCAT(p.p_name, ' (', p.p_type, ') - ', p.p_comment) AS detailed_part_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name
HAVING 
    total_available_quantity > 50
ORDER BY 
    total_orders DESC, avg_order_price DESC;
