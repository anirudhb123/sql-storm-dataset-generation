WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
), NationSales AS (
    SELECT n.n_name, SUM(l.l_extendedprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COALESCE(ns.total_sales, 0) AS total_sales,
    ARRAY_AGG(DISTINCT sh.s_name) AS suppliers,
    t.c_name AS top_customer,
    t.c_acctbal AS top_customer_balance
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN OrderSummary os ON ns.n_nationkey = os.o_orderkey
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN TopCustomers t ON t.rank = 1
GROUP BY r.r_name, ns.n_name, t.c_name, t.c_acctbal
ORDER BY total_sales DESC, region_name, nation_name;
