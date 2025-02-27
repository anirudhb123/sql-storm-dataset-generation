SELECT 
    p.mfgr AS manufacturer, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(l_discount) AS average_discount_rate,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_phone), ', ') AS supplier_contact_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.mfgr
HAVING 
    SUM(l_extendedprice * (1 - l_discount)) > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    supplier_count DESC, 
    total_returned_quantity DESC
LIMIT 10;
