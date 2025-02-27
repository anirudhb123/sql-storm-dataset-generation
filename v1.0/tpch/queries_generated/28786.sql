SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    REPLACE(p.p_comment, 'obsolete', 'updated') AS new_comment,
    CONCAT('Part:', p.p_partkey, ' | Name:', p.p_name) AS part_description,
    CASE
        WHEN LENGTH(p.p_name) > 20 THEN 'Long Name'
        ELSE 'Short Name'
    END AS name_length_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LOWER(p.p_mfgr) LIKE 'a%'
GROUP BY 
    SUBSTRING(p.p_name, 1, 10), 
    REPLACE(p.p_comment, 'obsolete', 'updated'),
    CONCAT('Part:', p.p_partkey, ' | Name:', p.p_name),
    CASE
        WHEN LENGTH(p.p_name) > 20 THEN 'Long Name'
        ELSE 'Short Name'
    END
ORDER BY 
    supplier_count DESC, 
    short_name ASC;
