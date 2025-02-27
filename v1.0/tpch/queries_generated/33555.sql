WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 3
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
), TotalSales AS (
    SELECT SUM(total_sales) AS grand_total
    FROM OrderSummary
), SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, sh.level, 
           RANK() OVER (PARTITION BY sh.level ORDER BY SUM(ps.ps_supplycost) DESC) AS rank,
           COALESCE(NULLIF(SUM(ps.ps_supplycost), 0), NULL) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, sh.level
)
SELECT s.s_name, s.total_supply_cost, 
       CASE 
           WHEN s.rank <= 5 THEN 'Top Supplier'
           WHEN s.rank <= 10 THEN 'Moderate Supplier'
           ELSE 'Underperforming Supplier'
       END AS supplier_category,
       COALESCE(ts.grand_total, 0) AS grand_total_sales
FROM SupplierStats s, TotalSales ts
ORDER BY s.level, s.total_supply_cost DESC;
