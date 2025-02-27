WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 
           1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 YEAR'
)

SELECT 
    c.c_name AS Customer_Name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Sales_Rank,
    CASE WHEN COUNT(DISTINCT l.l_orderkey) > 5 THEN 'High Volume' ELSE 'Low Volume' END AS Volume_Category,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Row_Number
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE o.o_orderdate >= (SELECT DATEADD(month, -12, CURRENT_DATE))
AND (p.p_size > 10 OR p.p_retailprice > 100.00)
GROUP BY c.c_name, c.c_nationkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY Total_Sales DESC
LIMIT 10;
