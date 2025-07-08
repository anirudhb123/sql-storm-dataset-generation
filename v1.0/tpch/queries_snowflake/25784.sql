
SELECT 
    p.p_name,
    LENGTH(p.p_name) AS name_length,
    UPPER(p.p_comment) AS comment_uppercase,
    SUBSTRING(p.p_type, 1, 10) AS type_substring,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS manufacturer_brand,
    (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_partkey = p.p_partkey) AS avg_supplycost
FROM 
    part p
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
GROUP BY 
    p.p_name,
    p.p_comment,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_partkey
ORDER BY 
    name_length DESC, 
    p.p_name ASC
LIMIT 50;
