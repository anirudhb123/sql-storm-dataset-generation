
SELECT 
    p.p_name,
    substring(p.p_comment, 1, 10) AS short_comment,
    replace(lower(p.p_mfgr), ' ', '-') AS modified_mfgr,
    concat(p.p_brand, ' - ', p.p_type) AS brand_type,
    (SELECT 
        count(DISTINCT l.l_orderkey) 
     FROM 
        lineitem l 
     WHERE 
        l.l_partkey = p.p_partkey) AS order_count,
    (SELECT 
        sum(ps.ps_availqty) 
     FROM 
        partsupp ps 
     WHERE 
        ps.ps_partkey = p.p_partkey) AS total_quantity_available
FROM 
    part p 
WHERE 
    upper(p.p_name) LIKE 'A%' 
    AND p.p_retailprice > 100 
GROUP BY 
    p.p_name, 
    p.p_comment, 
    p.p_mfgr, 
    p.p_brand, 
    p.p_type, 
    p.p_partkey
ORDER BY 
    p.p_partkey DESC 
LIMIT 10;
