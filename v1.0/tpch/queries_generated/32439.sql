WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalSales,
           COUNT(DISTINCT li.l_suppkey) AS UniqueSuppliers,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS OrderRank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT s.s_name, COUNT(DISTINCT o.o_orderkey) AS OrderCount,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalSales
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
          AND o.o_orderstatus = 'O'
    GROUP BY s.s_name
),
FinalReport AS (
    SELECT s.s_name, COALESCE(s.TotalSales, 0) AS SupplierTotalSales,
           COALESCE(o.TotalSales, 0) AS OrderTotalSales,
           sh.Level
    FROM SupplierSales s
    FULL OUTER JOIN OrderStats o ON s.OrderCount = o.UniqueSuppliers
    LEFT JOIN SupplierHierarchy sh ON s.s_name = sh.s_name
    WHERE s.SupplierTotalSales IS NOT NULL OR o.OrderTotalSales IS NOT NULL
)
SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS NationCount,
       SUM(fr.SupplierTotalSales) AS TotalSupplierSales,
       AVG(fr.OrderTotalSales) AS AverageOrderSales,
       STRING_AGG(CONCAT(fr.suppliername, ': ', fr.SupplierTotalSales), ', ') AS Suppliers
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN FinalReport fr ON n.n_nationkey = fr.Level
GROUP BY r.r_name
ORDER BY TotalSupplierSales DESC, NationCount ASC;
