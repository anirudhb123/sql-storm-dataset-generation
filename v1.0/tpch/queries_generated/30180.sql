WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 10000 AND sh.Level < 5
),
HighlyActiveOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
SupplierPerformance AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
FinalMetrics AS (
    SELECT p.p_partkey, p.p_name, sp.TotalSupplyCost, COUNT(DISTINCT ha.o_orderkey) AS ActiveOrderCount, sh.Level
    FROM part p
    LEFT JOIN SupplierPerformance sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN HighlyActiveOrders ha ON ha.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%A%' LIMIT 1)
    LEFT JOIN SupplierHierarchy sh ON sp.s_name = sh.s_name
    GROUP BY p.p_partkey, p.p_name, sp.TotalSupplyCost, sh.Level
)

SELECT 
    f.p_partkey, 
    f.p_name, 
    f.TotalSupplyCost, 
    f.ActiveOrderCount,
    CASE 
        WHEN f.TotalSupplyCost IS NULL THEN 'No Supply Cost'
        WHEN f.ActiveOrderCount = 0 THEN 'No Active Orders'
        ELSE 'Active'
    END AS OrderStatus,
    ROW_NUMBER() OVER (PARTITION BY f.Level ORDER BY f.TotalSupplyCost DESC) AS RankInLevel
FROM FinalMetrics f
WHERE f.TotalSupplyCost IS NOT NULL
ORDER BY f.TotalSupplyCost DESC, f.ActiveOrderCount DESC;
