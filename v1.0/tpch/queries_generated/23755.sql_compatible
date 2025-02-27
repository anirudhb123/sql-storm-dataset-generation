
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < (SELECT COUNT(DISTINCT n.n_nationkey) FROM nation n)
),
SalesData AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY o.o_orderkey
),
FilteredSales AS (
    SELECT sd.o_orderkey, sd.total_sales
    FROM SalesData sd
    WHERE sd.sales_rank = 1
),
NationSales AS (
    SELECT n.n_name, SUM(fs.total_sales) AS total_nation_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN FilteredSales fs ON o.o_orderkey = fs.o_orderkey
    GROUP BY n.n_name
)
SELECT ns.n_name, ns.total_nation_sales, 
       COALESCE(NULLIF(ns.total_nation_sales, (SELECT MAX(total_nation_sales) FROM NationSales)), 0) AS adjusted_sales
FROM NationSales ns
WHERE ns.total_nation_sales < (SELECT AVG(total_nation_sales) FROM NationSales)
ORDER BY adjusted_sales DESC
LIMIT 10;
