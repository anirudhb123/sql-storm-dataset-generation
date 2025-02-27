WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
EligibleCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT os.o_orderkey, os.total_sales,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM os.o_orderdate) ORDER BY os.total_sales DESC) AS order_rank
    FROM OrderSummary os
),
SupplierStatistics AS (
    SELECT s.r_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, SUM(sh.s_acctbal) AS total_balance
    FROM SupplierHierarchy sh
    JOIN nation n ON sh.s_nationkey = n.n_nationkey
    JOIN region s ON n.n_regionkey = s.r_regionkey
    GROUP BY s.r_name
)
SELECT e.c_custkey, e.c_name, e.c_acctbal, o.total_sales, sr.supplier_count, sr.total_balance
FROM EligibleCustomers e
LEFT JOIN RankedOrders o ON e.c_custkey = o.o_orderkey
LEFT JOIN SupplierStatistics sr ON sr.supplier_count > 0
WHERE e.c_acctbal IS NOT NULL
AND (o.total_sales IS NULL OR o.total_sales > 1000)
ORDER BY e.c_acctbal DESC, o.total_sales DESC;
