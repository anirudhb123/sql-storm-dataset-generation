SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    n.n_name AS Nation_Name,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count,
    SUM(l.l_quantity) AS Total_Quantity,
    AVG(l.l_extendedprice) AS Avg_Extended_Price,
    STRING_AGG(l.l_comment, '; ') AS Combined_Comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE 'rubber%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Total_Quantity DESC, Avg_Extended_Price ASC;