WITH string_metrics AS (
    SELECT 
        p.p_name AS part_name, 
        LENGTH(p.p_name) AS name_length, 
        LOWER(p.p_mfgr) AS manufacturer_lower, 
        UPPER(p.p_type) AS type_upper, 
        CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', UPPER(p.p_type)) AS formatted_description
    FROM part p
    WHERE p.p_size >= 10
)
SELECT 
    sm.part_name, 
    sm.name_length, 
    sm.manufacturer_lower, 
    sm.type_upper, 
    sm.formatted_description, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM string_metrics sm
LEFT JOIN partsupp ps ON sm.part_name LIKE '%' || SUBSTRING(ps.ps_comment FROM 1 FOR 20) || '%'
LEFT JOIN lineitem l ON l.l_partkey = ps.ps_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
GROUP BY sm.part_name, sm.name_length, sm.manufacturer_lower, sm.type_upper, sm.formatted_description
ORDER BY sm.name_length DESC, sm.part_name ASC;
