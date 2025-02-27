SELECT 
    p.p_name AS Part_Name, 
    s.s_name AS Supplier_Name, 
    c.c_name AS Customer_Name, 
    o.o_orderkey AS Order_Key, 
    COUNT(DISTINCT l.l_linenumber) AS Line_Item_Count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    SUM(l.l_tax) AS Total_Tax,
    AVG(CASE WHEN l.l_returnflag = 'Y' THEN l.l_quantity ELSE NULL END) AS Avg_Returned_Quantity,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', l.l_comment), '; ') AS Supplier_Comments
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
WHERE 
    p.p_retailprice > 50.00 AND
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' AND
    c.c_mktsegment IN ('BUILDING', 'CONSTRUCTION')
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    Total_Revenue DESC, Line_Item_Count DESC;