WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS part_count, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT ps.ps_suppkey, SUM(os.total_revenue) AS supplier_revenue
    FROM partsupp ps
    JOIN OrderSummary os ON ps.ps_partkey = os.o_orderkey
    GROUP BY ps.ps_suppkey
)
SELECT nh.n_name, 
       COALESCE(sr.supplier_revenue, 0) AS total_revenue,
       r.r_name AS region_name,
       CUME_DIST() OVER (PARTITION BY r.r_name ORDER BY COALESCE(sr.supplier_revenue, 0) DESC) AS revenue_rank
FROM nation nh
LEFT JOIN SupplierRevenue sr ON nh.n_nationkey = sr.ps_suppkey
JOIN region r ON nh.n_regionkey = r.r_regionkey
WHERE nh.n_comment IS NOT NULL
  AND (sr.supplier_revenue > 50000 OR sr.supplier_revenue IS NULL)
ORDER BY r.r_name, total_revenue DESC;
