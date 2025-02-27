SELECT 
    CONCAT(c.c_name, ' - ', s.s_name) AS Customer_Supplier,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS Short_Comment,
    r.r_name AS Region_Name,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
GROUP BY 
    Customer_Supplier, r.r_name, Short_Comment
HAVING 
    Total_Sales > 10000
ORDER BY 
    Total_Sales DESC;
