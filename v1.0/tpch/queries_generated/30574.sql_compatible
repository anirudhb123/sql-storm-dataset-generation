
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS s_acctbal,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS s_acctbal,
           h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_nationkey = h.s_nationkey
    WHERE h.level < 5
),

OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS customer_count, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),

FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    WHERE r.r_comment LIKE '%Great%' OR r.r_comment IS NULL
)

SELECT 
    SUM(osh.total_revenue) AS total_sales,
    COUNT(DISTINCT osh.o_orderkey) AS total_orders,
    (SELECT COUNT(*) FROM customer c WHERE c.c_acctbal > 5000.00) AS high_value_customers,
    COALESCE(AVG(sh.s_acctbal), 0) AS avg_supplier_balance,
    fr.r_name,
    ROW_NUMBER() OVER (PARTITION BY fr.r_regionkey ORDER BY SUM(osh.total_revenue) DESC) AS revenue_rank
FROM OrderSummary osh
LEFT JOIN SupplierHierarchy sh ON osh.o_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
JOIN FilteredRegions fr ON fr.r_regionkey = (SELECT r.r_regionkey FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE n.n_nationkey = sh.s_nationkey)
WHERE osh.total_revenue > 1000.00
GROUP BY fr.r_regionkey, fr.r_name
HAVING COUNT(DISTINCT osh.o_orderkey) > 10
ORDER BY total_sales DESC;
