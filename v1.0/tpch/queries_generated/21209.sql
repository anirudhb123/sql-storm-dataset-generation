WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal IS NOT NULL
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS r_name, 
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, sh.level,
           nt.customer_count, nt.total_acctbal,
           ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.s_acctbal DESC) AS rn
    FROM SupplierHierarchy sh
    JOIN NationDetails nt ON sh.s_nationkey = nt.n_nationkey
),
ExtremeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
    HAVING COUNT(DISTINCT l.l_orderkey) > 10 AND SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem)
)
SELECT ts.s_suppkey, ts.s_name, ts.s_acctbal, ts.customer_count, 
       eo.order_count, eo.total_sales,
       COALESCE(NULLIF(ts.total_acctbal, 0), (SELECT AVG(s_acctbal) FROM supplier)) AS adjusted_acctbal
FROM TopSuppliers ts
FULL OUTER JOIN ExtremeOrders eo ON ts.rn = eo.order_count
WHERE ts.level < 3 AND (eo.total_sales IS NULL OR eo.total_sales > 5000.00)
ORDER BY adjusted_acctbal DESC, order_count ASC;
