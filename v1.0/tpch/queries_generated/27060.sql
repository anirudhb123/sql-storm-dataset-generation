SELECT 
    CONCAT(p.p_name, ' | ', s.s_name, ' | ', c.c_name) AS combined_info,
    UPPER(SUBSTRING(p.p_comment, 1, 10)) AS short_comment,
    LENGTH(p.p_name) AS name_length,
    CUSTOM_FUNCTION(p.p_type, s.s_nationkey) AS custom_type_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND s.s_acctbal > 1000.00
ORDER BY 
    name_length DESC, short_comment;
