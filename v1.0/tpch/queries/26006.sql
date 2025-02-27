SELECT 
    s.s_name AS Supplier_Name,
    COUNT(DISTINCT p.p_partkey) AS Unique_Parts_Supplied,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    STRING_AGG(DISTINCT CONCAT('Part: ', p.p_name, ' | Type: ', p.p_type), '; ') AS Part_Descriptions
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 1000.00 
    AND p.p_name LIKE 'F%'
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    Total_Available_Quantity DESC;
