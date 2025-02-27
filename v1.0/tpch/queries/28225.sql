SELECT 
    CONCAT(s.s_name, ' from ', c.c_name, ' located at ', c.c_address) AS Supplier_Customer_Info,
    p.p_name AS Part_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_quantity) AS Total_Quantity_Supplied,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Average_Sale_Price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS Regions_Supplied
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    s.s_name, c.c_name, c.c_address, p.p_name
ORDER BY 
    Total_Quantity_Supplied DESC, Average_Sale_Price DESC;