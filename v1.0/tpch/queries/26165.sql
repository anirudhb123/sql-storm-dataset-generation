SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type, ', Size: ', CAST(p.p_size AS VARCHAR), ', Container: ', p.p_container) AS part_details,
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    s.s_phone AS supplier_phone,
    (SELECT SUM(ps.ps_availqty) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS total_available_quantity,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM orders o 
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
     WHERE l.l_partkey = p.p_partkey AND o.o_orderstatus = 'F') AS total_fulfilled_orders,
    string_agg(DISTINCT n.n_name, ', ') AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, s.s_name, s.s_address, s.s_phone
ORDER BY 
    total_available_quantity DESC, total_fulfilled_orders DESC;
