SELECT 
    CONCAT('Part Name: ', p.p_name, ', Supplier Name: ', s.s_name) AS part_supplier_info,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS truncated_comment,
    REPLACE(s.s_address, 'Street', 'St.') AS modified_address,
    CHAR_LENGTH(p.p_type) AS type_length,
    p.p_retailprice * 1.2 AS inflated_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 5 AND 15
    AND s.s_acctbal > 1000
    AND (p.p_comment LIKE '%high%' OR s.s_comment LIKE '%premium%')
ORDER BY 
    inflated_price DESC
LIMIT 10;
