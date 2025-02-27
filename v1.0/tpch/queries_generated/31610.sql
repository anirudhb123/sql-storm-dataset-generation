WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal
)
, TopNations AS (
    SELECT n.n_name, SUM(s.s_acctbal) as total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.n_nationkey
    GROUP BY n.n_name
    HAVING COUNT(s.s_suppkey) > 5
)
, DiscountedSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.07
    GROUP BY l.l_orderkey
)
SELECT rh.n_name,
       COUNT(DISTINCT rh.s_suppkey) AS total_suppliers,
       AVG(rh.s_acctbal) AS avg_acctbal,
       SUM(ds.sales) AS total_sales,
       CASE 
           WHEN SUM(ds.sales) IS NULL THEN 'No Sales'
           ELSE CONCAT('Total Sales: ', SUM(ds.sales))
       END AS sales_summary
FROM SupplierHierarchy rh
LEFT JOIN TopNations tn ON rh.n_nationkey = tn.n_nationkey
LEFT JOIN DiscountedSales ds ON rh.s_suppkey IN (
    SELECT DISTINCT l.l_suppkey 
    FROM lineitem l 
    WHERE l.l_orderkey = ds.l_orderkey
)
GROUP BY rh.n_name
ORDER BY total_suppliers DESC, avg_acctbal DESC
FETCH FIRST 10 ROWS ONLY;
