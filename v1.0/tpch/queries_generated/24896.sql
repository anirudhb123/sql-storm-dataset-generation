WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Depth < 10
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

PartSuppliers AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS TotalAvailable, p.p_name, p.p_retailprice
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),

SupplierPerformance AS (
    SELECT sh.s_suppkey, sh.s_name, COUNT(DISTINCT ps.ps_partkey) AS PartsSupplied,
           AVG(ps.ps_supplycost) AS AvgSupplyCost, SUM(sh.Depth) AS TotalDepth
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name
)

SELECT DISTINCT 
    COALESCE(c.c_name, 'Unknown Customer') AS CustomerName,
    COALESCE(o.OrderCount, 0) AS OrderCount,
    COALESCE(o.TotalSpent, 0) AS TotalSpent,
    COALESCE(p.p_name, 'No Parts') AS PartName,
    COALESCE(sp.PartsSupplied, 0) AS PartsSupplied,
    COALESCE(sp.AvgSupplyCost, 0) AS AvgSupplyCost,
    CASE 
        WHEN o.TotalSpent IS NULL OR o.TotalSpent < 100 THEN 'Low Spender'
        WHEN o.TotalSpent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS SpendingCategory,
    RANK() OVER (PARTITION BY CASE 
                                  WHEN o.TotalSpent IS NULL THEN 'No Orders'
                                  ELSE 'With Orders' END 
                 ORDER BY o.TotalSpent DESC) AS SpendingRank
FROM CustomerOrders o
FULL OUTER JOIN part p ON p.p_container IS NOT NULL AND p.p_size > 0
LEFT JOIN SupplierPerformance sp ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
FULL JOIN region r ON r.r_regionkey IS NULL
LEFT JOIN nation n ON n.n_nationkey = o.c_custkey AND n.n_regionkey IS NOT NULL
ORDER BY SpendingRank, CustomerName;
