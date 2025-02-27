WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_custkey = oh.o_custkey)
      AND o.o_orderstatus <> 'F'
)

SELECT 
    n.n_name AS Nation, 
    r.r_name AS Region,
    COUNT(DISTINCT c.c_custkey) AS Total_Customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(l.l_quantity) AS Avg_Quantity,
    MAX(o.o_totalprice) AS Max_Order_Amount,
    MIN(o.o_orderdate) AS Earliest_Order_Date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS Part_Names,
    SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS Valid_Supplier_Balance
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    r.r_name LIKE 'Northeast%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    Total_Revenue DESC
LIMIT 10;