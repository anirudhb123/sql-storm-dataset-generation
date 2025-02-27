
SELECT 
    s.s_name AS Supplier_Name,
    COUNT(DISTINCT ps.ps_partkey) AS Num_Parts_Supplied,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Supply_Cost,
    AVG(p.p_retailprice) AS Avg_Retail_Price,
    STRING_AGG(DISTINCT p.p_type, ', ') AS Unique_Part_Types,
    SUBSTRING(s.s_comment, 1, 50) AS Supplier_Comment_Preview
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name, s.s_comment
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 10 AND 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
ORDER BY 
    Total_Supply_Cost DESC
LIMIT 5;
