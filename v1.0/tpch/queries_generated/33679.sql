WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredSales AS (
    SELECT ts.o_orderkey, ts.total_sales, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ts.total_sales DESC) AS rnk
    FROM TotalSales ts
    JOIN customer c ON ts.o_orderkey = c.c_custkey
    JOIN supplier s ON c.c_nationkey = s.s_nationkey
    WHERE ts.total_sales > 50000
)
SELECT s.s_name, s.s_acctbal, fs.total_sales
FROM SupplierHierarchy s
LEFT JOIN FilteredSales fs ON s.s_suppkey = fs.o_orderkey
WHERE fs.rnk IS NOT NULL OR s.level > 1
ORDER BY s.s_acctbal DESC, fs.total_sales DESC
LIMIT 10;
