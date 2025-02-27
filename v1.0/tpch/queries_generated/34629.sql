WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
AggregatedSales AS (
    SELECT l.l_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, as.total_sales
    FROM supplier s
    LEFT JOIN AggregatedSales as ON s.s_suppkey = as.l_suppkey
    WHERE as.total_sales IS NOT NULL
    ORDER BY total_sales DESC
    FETCH FIRST 10 ROWS ONLY
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, 
           COALESCE(as.total_sales, 0) AS total_sales, sh.level
    FROM supplier s
    LEFT JOIN TopSuppliers as ON s.s_suppkey = as.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT sd.s_suppkey, sd.s_name, sd.s_address, sd.nation_name, 
       sd.total_sales, sd.level,
       RANK() OVER (PARTITION BY sd.nation_name ORDER BY sd.total_sales DESC) AS sales_rank
FROM SupplierDetails sd
WHERE sd.level IS NOT NULL
  AND sd.total_sales > 5000
ORDER BY sd.nation_name, sales_rank;
