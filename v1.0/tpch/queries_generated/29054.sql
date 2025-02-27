SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    o.o_orderkey AS Order_Number,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    COUNT(DISTINCT o.o_orderkey) AS Number_of_Orders,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name ASC SEPARATOR ', '), ', ', 3) AS Top_Regions,
    LEFT(p.p_comment, 10) AS Short_Comment
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
    l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey
HAVING 
    Revenue > 10000
ORDER BY 
    Revenue DESC;
