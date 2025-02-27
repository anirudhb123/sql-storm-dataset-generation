SELECT 
    s.s_name AS Supplier_Name,
    p.p_name AS Part_Name,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    AVG(o.o_totalprice) AS Average_Order_Value,
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
    s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = (
            SELECT r.r_regionkey 
            FROM region r 
            WHERE r.r_name = 'ASIA'
        )
    )
AND 
    o.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    Total_Available_Quantity DESC, Average_Order_Value DESC;