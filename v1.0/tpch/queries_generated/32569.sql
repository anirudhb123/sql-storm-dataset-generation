WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_custkey
), AvgSales AS (
    SELECT AVG(total_spent) AS average_spent
    FROM TotalSales
), SupplierStats AS (
    SELECT s.s_nationkey, COUNT(s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_balance
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_nationkey
), RankedSuppliers AS (
    SELECT n.n_name, ss.supplier_count, ss.total_balance, 
           ROW_NUMBER() OVER (ORDER BY ss.total_balance DESC) AS rank
    FROM SupplierStats ss
    JOIN nation n ON ss.s_nationkey = n.n_nationkey
)
SELECT rh.level, r.n_name, r.supplier_count, r.total_balance, 
       ts.total_spent, 
       (CASE WHEN ts.total_spent IS NOT NULL THEN ts.total_spent / (SELECT average_spent FROM AvgSales) ELSE NULL END) AS spending_ratio
FROM SupplierHierarchy rh
JOIN RankedSuppliers r ON rh.s_nationkey = r.s_nationkey
LEFT JOIN TotalSales ts ON rh.s_suppkey = ts.o_custkey
WHERE r.rank <= 10
ORDER BY rh.level, r.total_balance DESC;
