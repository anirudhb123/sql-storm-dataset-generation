SELECT 
    SUBSTRING(p.p_name, 1, 15) AS Short_Name,
    COUNT(DISTINCT s.s_suppkey) AS Unique_Suppliers,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    AVG(p.p_retailprice) AS Average_Retail_Price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS Customer_Names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
WHERE 
    p.p_size > 10 AND 
    s.s_acctbal > 1000
GROUP BY 
    Short_Name
ORDER BY 
    Total_Available_Quantity DESC 
LIMIT 20;
