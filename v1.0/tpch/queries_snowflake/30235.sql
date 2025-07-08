WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey
),
SalesPerSupplier AS (
    SELECT s.s_suppkey, SUM(ts.total_sales) AS supplier_sales
    FROM TotalSales ts
    JOIN partsupp ps ON ts.o_orderkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    COALESCE(sp.supplier_sales, 0) AS total_sales,
    RANK() OVER (PARTITION BY r.r_regionkey ORDER BY COALESCE(sp.supplier_sales, 0) DESC) AS sales_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN SalesPerSupplier sp ON sh.s_suppkey = sp.s_suppkey
WHERE r.r_comment IS NULL OR r.r_comment != ''
ORDER BY r.r_name, sales_rank;