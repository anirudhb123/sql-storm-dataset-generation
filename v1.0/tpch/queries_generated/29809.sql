SELECT 
    s.s_name AS Supplier_Name,
    COUNT(DISTINCT ps.ps_partkey) AS Unique_Parts_Supplied,
    SUM(l.l_quantity) AS Total_Quantity_Supplied,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Average_Price_After_Discount,
    STRING_AGG(DISTINCT SUBSTRING(p.p_name, 1, 10), ', ') AS Sample_Part_Names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    s.s_acctbal > 1000
GROUP BY 
    s.s_suppkey, s.s_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    Total_Quantity_Supplied DESC
LIMIT 10;
