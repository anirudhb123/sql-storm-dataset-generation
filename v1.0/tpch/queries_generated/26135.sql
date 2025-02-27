SELECT 
    s.s_name AS Supplier_Name,
    p.p_name AS Part_Name,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    STRING_AGG(DISTINCT c.c_name, ', ') AS Customer_Names,
    STRING_AGG(DISTINCT n.n_name, ', ') AS Nation_Names
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    Total_Available_Quantity DESC;
