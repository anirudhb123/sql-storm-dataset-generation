WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_name, 1 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)
    
    UNION ALL
    
    SELECT s.n_nationkey, s.s_name, sh.level + 1
    FROM nation s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 

PartDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_size,
           (CASE 
                WHEN p.p_size IS NULL THEN 'Unknown Size' 
                WHEN p.p_size < 10 THEN 'Small' 
                WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium' 
                ELSE 'Large' 
           END) AS Size_Category
    FROM part p
),

HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'A')
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)

SELECT d.Size_Category, COUNT(DISTINCT o.o_orderkey) AS Order_Count,
       AVG(n.n_regionkey) AS Avg_Region, 
       SUM(COALESCE(s.s_acctbal, 0)) AS Total_Account_Balance
FROM PartDetail d
LEFT JOIN partsupp ps ON d.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN HighValueOrders o ON d.p_partkey = (SELECT TOP 1 l.l_partkey 
                                                FROM lineitem l 
                                                WHERE l.l_orderkey = o.o_orderkey)
WHERE n.r_regionkey IN (SELECT r.r_regionkey 
                         FROM region r 
                         WHERE r.r_name LIKE 'S%')
GROUP BY d.Size_Category
HAVING COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY Total_Account_Balance DESC NULLS LAST;
