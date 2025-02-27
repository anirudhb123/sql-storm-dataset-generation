SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    (CASE 
        WHEN LENGTH(p.p_name) > 30 THEN 'Long Name' 
        ELSE 'Short Name' 
    END) AS name_length_category,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name) AS product_info,
    s.s_comment || ' | ' || p.p_comment AS supplier_product_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
WHERE 
    p.p_retailprice > 50.00 
    AND s.s_acctbal < 1000.00 
    AND c.c_mktsegment = 'BUILDING'
ORDER BY 
    name_length_category, p.p_name;
