WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),

OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),

RankedDetails AS (
    SELECT od.o_orderkey, od.o_orderdate, od.total_sales,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM od.o_orderdate) ORDER BY od.total_sales DESC) AS sales_rank
    FROM OrderDetails od
)

SELECT r.r_name AS region_name,
       COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
       AVG(ps.ps_supplycost) AS avg_supplycost,
       SUM(ld.total_sales) AS total_sales_per_region,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', sh.level, ')')) AS suppliers_hierarchy
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN RankedDetails ld ON ld.o_orderkey = ps.ps_partkey
WHERE r.r_comment IS NOT NULL
  AND (s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000)
  AND ld.sales_rank <= 10
GROUP BY r.r_name
ORDER BY total_sales_per_region DESC;
