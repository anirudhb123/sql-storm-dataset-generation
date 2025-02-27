SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Price: $', FORMAT(p.p_retailprice, 2), ', Comment: ', p.p_comment) AS part_details,
    SUBSTRING_INDEX(s.s_name, ' ', 1 AS supplier_first_name,
    CASE 
        WHEN c.c_mktsegment = 'BUILDING' THEN 'Building Supplies'
        WHEN c.c_mktsegment = 'FURNITURE' THEN 'Furniture and Fixtures'
        ELSE 'Other'
    END AS market_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    LENGTH(p.p_name) > 20 
    AND p.p_retailprice BETWEEN 10 AND 100
    AND s.s_acctbal > 1000
ORDER BY 
    p.p_retailprice DESC, part_details ASC;
