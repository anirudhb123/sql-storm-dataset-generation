
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
AverageSales AS (
    SELECT AVG(ts.total_sales) AS avg_sales
    FROM TotalSales ts
)
SELECT n.n_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count, 
       COALESCE(MAX(rs.total_supply_cost), 0) AS max_supply_cost, 
       (SELECT avg_sales FROM AverageSales) AS avg_total_sales,
       COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN RankedSuppliers rs ON sh.s_suppkey = rs.s_suppkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
WHERE n.n_comment LIKE '%excellent%'
GROUP BY n.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY supplier_count DESC;
