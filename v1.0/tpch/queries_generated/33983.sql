WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey -- Example correlation, replace with correct logic for hierarchy
    WHERE s.s_acctbal > 1000
),
TopRegions AS (
    SELECT r.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
    HAVING TotalValue > 1000
),
RankedSuppliers AS (
    SELECT s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM supplier s
),
FinalResult AS (
    SELECT r.r_name, th.TotalSupplyCost, COUNT(ho.o_orderkey) AS RecentHighValueOrders
    FROM TopRegions tr
    LEFT JOIN RecentOrders ho ON tr.r_name = ho.c_name
    JOIN SupplierHierarchy sh ON tr.r_name = sh.s_name
    GROUP BY r.r_name, th.TotalSupplyCost
)
SELECT f.r_name, 
       f.TotalSupplyCost, 
       COALESCE(SUM(sh.s_acctbal), 0) AS TotalSupplierBalance,
       RANK() OVER (ORDER BY f.TotalSupplyCost DESC) AS SupplyCostRank
FROM FinalResult f
LEFT JOIN RankedSuppliers sh ON f.r_name = sh.s_name
WHERE f.TotalSupplyCost IS NOT NULL
GROUP BY f.r_name, f.TotalSupplyCost
ORDER BY f.TotalSupplyCost DESC;
