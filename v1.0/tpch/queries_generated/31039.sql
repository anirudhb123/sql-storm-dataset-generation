WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CASE 
               WHEN c.c_acctbal < 1000 THEN 'Low'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS acctbal_category,
           1 AS lvl
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, 
           CASE 
               WHEN ch.c_acctbal < 1000 THEN 'Low'
               WHEN ch.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS acctbal_category,
           lvl + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_custkey = c.c_custkey
    WHERE ch.acctbal_category = 'High' AND c.c_acctbal < 1000
),
AggregatedOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_ordered
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierPerformance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
NationRegionSuppliers AS (
    SELECT n.n_name, r.r_name, s.s_name, s.s_acctbal,
           DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ch.c_custkey, ch.c_name, ch.acctbal_category, a.total_ordered,
       np.n_name, np.r_name, np.s_name, np.s_acctbal,
       sp.total_sales, sp.sales_rank
FROM CustomerHierarchy ch
LEFT JOIN AggregatedOrders a ON ch.c_custkey = a.o_custkey
LEFT JOIN NationRegionSuppliers np ON ch.c_nationkey = np.n_nationkey
LEFT JOIN SupplierPerformance sp ON np.s_suppkey = sp.ps_suppkey
WHERE (ch.c_acctbal IS NOT NULL OR a.total_ordered IS NOT NULL)
  AND (sp.total_sales IS NOT NULL AND sp.sales_rank <= 5)
  AND np.s_acctbal > 1000
ORDER BY ch.acctbal_category, a.total_ordered DESC;
