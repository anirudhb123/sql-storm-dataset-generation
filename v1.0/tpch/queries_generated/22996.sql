WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
ExpandedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_price_adjusted
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
DisparateSuppliers AS (
    SELECT DISTINCT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL 
    GROUP BY s.s_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, 
           COUNT(DISTINCT n.n_nationkey) OVER(ORDER BY COUNT(DISTINCT n.n_nationkey) DESC) AS region_rank
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
FinalBenchmark AS (
    SELECT s.s_name, sh.level, e.o_orderkey, 
           CASE 
               WHEN e.total_price_adjusted IS NULL THEN 0
               ELSE e.total_price_adjusted
           END AS adjusted_price,
           CASE 
               WHEN t.region_rank <= 3 THEN 'Top Region'
               ELSE 'Other Region'
           END AS region_status
    FROM SupplierHierarchy sh
    JOIN ExpandedOrders e ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = sh.s_nationkey LIMIT 1)
    JOIN DisparateSuppliers ds ON sh.s_suppkey = ds.s_suppkey
    JOIN TopRegions t ON ds.part_count > 5
    WHERE sh.s_acctbal > (SELECT MAX(s_acctbal) FROM supplier WHERE s_comment LIKE '%excellent%')
)
SELECT DISTINCT f.s_name, f.level, f.o_orderkey, f.adjusted_price, f.region_status
FROM FinalBenchmark f
ORDER BY f.adjusted_price DESC, f.s_name
LIMIT 100 OFFSET 0;
