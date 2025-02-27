WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS Level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
TotalLineItems AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
AverageOrderValue AS (
    SELECT AVG(TotalPrice) AS AvgOrderPrice
    FROM TotalLineItems
),
EnhancedLineItems AS (
    SELECT l.l_orderkey, 
           l.l_partkey, 
           l.l_suppkey, 
           l.l_quantity,
           l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS row_num,
           CASE WHEN l.l_discount < 0.1 THEN 'Low discount' ELSE 'High discount' END AS DiscountCategory
    FROM lineitem l
)
SELECT p.p_partkey,
       p.p_name,
       p.p_brand,
       p.p_type,
       SUM(CASE WHEN e.row_num = 1 THEN e.l_extendedprice END) AS HighestSalePrice,
       COUNT(DISTINCT e.l_orderkey) AS NumberOfOrders,
       AVG(s.s_acctbal) AS AverageSupplierBalance,
       r.r_name AS RegionName
FROM part p
LEFT JOIN EnhancedLineItems e ON p.p_partkey = e.l_partkey
LEFT JOIN supplier s ON e.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size = (SELECT MAX(p_size) FROM part WHERE p_retailprice > 100.00)
   AND EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = s.s_nationkey)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, r.r_name
HAVING COUNT(DISTINCT e.l_orderkey) > (SELECT AvgOrderPrice FROM AverageOrderValue)
ORDER BY HighestSalePrice DESC;
