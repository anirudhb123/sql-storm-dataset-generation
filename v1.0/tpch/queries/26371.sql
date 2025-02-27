SELECT 
    s.s_name AS Supplier_Name, 
    p.p_name AS Part_Name, 
    p.p_size AS Part_Size, 
    COUNT(l.l_orderkey) AS Total_Orders, 
    SUM(l.l_extendedprice) AS Total_Extended_Price, 
    AVG(l.l_discount) AS Average_Discount,
    MAX(CASE WHEN l.l_shipdate >= '1997-01-01' THEN l.l_tax ELSE 0 END) AS Max_Tax_After_1997,
    STRING_AGG(DISTINCT c.c_name, ', ') AS Customer_Names
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%fragile%'
GROUP BY 
    s.s_name, p.p_name, p.p_size
ORDER BY 
    Total_Extended_Price DESC
LIMIT 10;