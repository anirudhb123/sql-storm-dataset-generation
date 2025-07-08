WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > 10000
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(distinct l.l_linenumber) AS item_count,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SalesRanked AS (
    SELECT os.o_orderkey, os.total_sales, os.item_count,
           RANK() OVER (ORDER BY os.total_sales DESC) AS sales_rank
    FROM OrderSummary os
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_sales) AS nation_total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN OrderSummary os ON l.l_orderkey = os.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, n.nation_total_sales, 
       COALESCE(s.sales_rank, 0) AS sales_rank,
       CASE WHEN n.nation_total_sales > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM NationSales n
LEFT JOIN SalesRanked s ON n.n_nationkey = s.o_orderkey
JOIN HighValueCustomers hvc ON hvc.c_custkey = s.o_orderkey
WHERE n.nation_total_sales IS NOT NULL
ORDER BY n.nation_total_sales DESC, sales_rank;
