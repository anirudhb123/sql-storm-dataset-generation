SELECT 
    s.s_name AS Supplier_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(l.l_quantity) AS Average_Quantity,
    MAX(l.l_shipdate) AS Last_Shipment_Date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS Product_Names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    Total_Revenue DESC;