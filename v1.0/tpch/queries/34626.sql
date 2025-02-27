
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal + sh.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1998-10-01' - INTERVAL '1 year' AND DATE '1998-10-01'
    GROUP BY o.o_custkey
),
CustomerRegion AS (
    SELECT c.c_custkey, r.r_name AS region_name, cs.total_sales
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN OrderSummary cs ON c.c_custkey = cs.o_custkey
    WHERE r.r_name IS NOT NULL
)
SELECT cr.region_name, COUNT(DISTINCT cr.c_custkey) AS customer_count,
       AVG(COALESCE(cr.total_sales, 0)) AS avg_sales,
       MAX(sh.s_acctbal) AS max_supplier_balance
FROM CustomerRegion cr
LEFT JOIN SupplierHierarchy sh ON cr.region_name = sh.s_name
GROUP BY cr.region_name
HAVING AVG(COALESCE(cr.total_sales, 0)) > 10000
ORDER BY customer_count DESC, avg_sales DESC;
