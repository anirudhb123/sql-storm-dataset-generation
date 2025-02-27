SELECT 
    p.p_partkey,
    UPPER(p.p_name) AS part_name_upper,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS manufacturer_brand,
    CASE 
        WHEN p.p_size > 10 THEN 'Large'
        WHEN p.p_size BETWEEN 6 AND 10 THEN 'Medium'
        ELSE 'Small'
    END AS size_category,
    REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS clean_comment,
    r.r_name AS region_name,
    SUBSTRING_INDEX(n.n_name, ' ', 1) AS nation_initial,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_account_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100
    AND s.s_acctbal < 5000
ORDER BY 
    size_category DESC, 
    p.p_partkey ASC 
LIMIT 
    50;
