SELECT 
    p.p_name AS Product_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    o.o_orderkey AS Order_Key,
    COUNT(DISTINCT l.l_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    MAX(l.l_shipdate) AS Last_Ship_Date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS Regions_Served
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 25 AND 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31' AND
    c.c_mktsegment = 'Furniture'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    Total_Revenue DESC;