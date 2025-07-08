
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY n.n_nationkey, n.n_name
),
SalesRanked AS (
    SELECT n.n_name, ns.total_sales,
           DENSE_RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM NationSales ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
),
TopRegions AS (
    SELECT r.r_name, SUM(ns.total_sales) AS region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationSales ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY r.r_name
    HAVING SUM(ns.total_sales) > 100000
)
SELECT sr.n_name, sr.total_sales, sr.sales_rank, tr.r_name, tr.region_sales
FROM SalesRanked sr
FULL OUTER JOIN TopRegions tr ON sr.sales_rank = 1
WHERE tr.region_sales IS NOT NULL OR sr.total_sales IS NOT NULL
ORDER BY sr.sales_rank, tr.region_sales DESC;
