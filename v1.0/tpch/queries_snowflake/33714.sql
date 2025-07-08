WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) * 0.8
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderTotals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerPurchases AS (
    SELECT c.c_custkey, SUM(ot.total_sales) AS total_purchases
    FROM customer c
    LEFT JOIN OrderTotals ot ON c.c_custkey = ot.o_orderkey
    GROUP BY c.c_custkey
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(cp.total_purchases) AS nation_total
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerPurchases cp ON c.c_custkey = cp.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, COALESCE(ns.nation_total, 0) AS total_sales, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       ROW_NUMBER() OVER (ORDER BY COALESCE(ns.nation_total, 0) DESC) AS rn
FROM nation n
LEFT JOIN NationSales ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY n.n_name, ns.nation_total
HAVING COUNT(s.s_suppkey) > 0
ORDER BY total_sales DESC, n.n_name ASC;
