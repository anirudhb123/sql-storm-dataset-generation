SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: $', FORMAT(p.p_retailprice, 2)) AS detail_summary,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    CONCAT(REPLACE(p.p_container, 'Box', 'Container'), ' - Size: ', p.p_size) AS modified_container_description
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 50.00
    AND LENGTH(p.p_name) > 10
ORDER BY 
    p.p_retailprice DESC
LIMIT 100;
