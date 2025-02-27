WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal >= sh.s_acctbal * 0.5
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_extendedprice * l.l_discount) AS total_discount
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY n.n_nationkey, n.n_name
),
RegionStats AS (
    SELECT r.r_regionkey, r.r_name, AVG(np.total_sales) AS avg_sales,
           MAX(np.total_sales) AS max_sales, MIN(np.total_sales) AS min_sales
    FROM region r
    LEFT JOIN NationPerformance np ON r.r_regionkey = np.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rh.s_name, rh.level, r.r_name AS region_name, 
       ROUND(r.avg_sales, 2) AS avg_region_sales, 
       ROUND(r.max_sales, 2) AS max_region_sales, 
       ROUND(r.min_sales, 2) AS min_region_sales
FROM SupplierHierarchy rh
JOIN RegionStats r ON rh.s_nationkey = r.r_regionkey
WHERE rh.level <= 2
ORDER BY r.avg_sales DESC, rh.s_name;
