WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 100)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
), RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
), SupplierStats AS (
    SELECT sh.s_name, COUNT(DISTINCT ps.ps_partkey) AS PartsSupplied, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_name
), OrderSummary AS (
    SELECT COUNT(DISTINCT lo.l_orderkey) AS OrderCount, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS Revenue
    FROM lineitem lo
    JOIN RecentOrders ro ON lo.l_orderkey = ro.o_orderkey
    WHERE lo.l_shipdate BETWEEN DATEADD(day, -30, CURRENT_DATE) AND CURRENT_DATE
)

SELECT sh.s_name, ss.PartsSupplied, ss.TotalSupplyValue, os.OrderCount, os.Revenue
FROM SupplierStats ss
JOIN OrderSummary os ON ss.PartsSupplied > 10
JOIN SupplierHierarchy sh ON ss.s_name = sh.s_name
ORDER BY os.Revenue DESC, ss.TotalSupplyValue DESC;
