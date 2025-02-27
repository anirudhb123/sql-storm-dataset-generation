SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    COUNT(o.o_orderkey) AS Total_Orders,
    SUM(l.l_quantity) AS Total_Quantity,
    AVG(l.l_extendedprice) AS Avg_Extended_Price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS Nations_Supplied,
    MAX(p.p_retailprice) AS Max_Retail_Price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_comment LIKE '%Fragile%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Part_Name, Supplier_Name;