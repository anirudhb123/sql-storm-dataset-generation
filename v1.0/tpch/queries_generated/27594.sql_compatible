
SELECT 
    p.p_name AS part_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS part_manufacturer_brand,
    SUBSTRING(p.p_comment, 1, 20) AS truncated_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.o_totalprice) AS total_order_value,
    STRING_AGG(DISTINCT s.s_name, '; ' ORDER BY s.s_name) AS supplier_names
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
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_comment
ORDER BY 
    total_order_value DESC, part_name ASC;
