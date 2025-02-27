WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 
           1 AS Level, 
           CONCAT('Level 1 - Order Key: ', o_orderkey) AS OrderPath
    FROM orders
    WHERE o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           oh.Level + 1, 
           CONCAT(oh.OrderPath, ' > Level ', oh.Level + 1, ' - Order Key: ', o.o_orderkey)
    FROM orders o 
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE oh.Level < 3
),
LineItemStats AS (
    SELECT l_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS TotalRevenue, 
           COUNT(l_linenumber) AS LineCount
    FROM lineitem
    GROUP BY l_orderkey
),
SupplierAvgCost AS (
    SELECT ps.ps_partkey, 
           AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CombinedResults AS (
    SELECT oh.o_orderkey, 
           oh.o_totalprice, 
           lis.TotalRevenue, 
           lis.LineCount,
           COALESCE(sup.AvgSupplyCost, 0) AS AvgSupplyCost
    FROM OrderHierarchy oh
    LEFT JOIN LineItemStats lis ON oh.o_orderkey = lis.l_orderkey
    LEFT JOIN SupplierAvgCost sup ON lis.LineCount > 0 -- Just to ensure we have meaningful joins
)
SELECT r.r_name,
       COUNT(DISTINCT cr.o_orderkey) AS OrderCount,
       AVG(cr.o_totalprice) AS AvgTotalPrice,
       SUM(cr.TotalRevenue) AS TotalRevenue,
       SUM(cr.AvgSupplyCost) AS TotalAvgSupplierCost,
       STRING_AGG(DISTINCT cr.OrderPath, '; ') AS OrderPaths
FROM CombinedResults cr
JOIN customer c ON cr.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE cr.TotalRevenue IS NOT NULL
  AND cr.TotalRevenue > 500
GROUP BY r.r_name
HAVING AVG(cr.o_totalprice) < 1000
ORDER BY r.r_name;
