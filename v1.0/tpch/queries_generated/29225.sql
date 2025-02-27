SELECT 
    CONCAT(s_name, ' from ', r_name, ' needs ', ps_availqty, ' of ', p_name) AS Supplier_Product_Need,
    LENGTH(p_comment) AS Comment_Length,
    UPPER(p_type) AS Uppercase_Type,
    SUBSTRING(s_comment, 1, 30) || '...' AS Shortened_Comment,
    COUNT(DISTINCT c_custkey) OVER (PARTITION BY s_nationkey ORDER BY s_suppkey) AS Unique_Customers_Served
FROM 
    supplier s 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p_retailprice > 50.00 
    AND s_comment LIKE '%loyal%'
ORDER BY 
    Comment_Length DESC, Uppercase_Type
LIMIT 100;
