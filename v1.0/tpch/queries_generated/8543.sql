WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
SalesSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY l.l_orderkey
),
TopRegions AS (
    SELECT n.n_regionkey, SUM(s.s_acctbal) AS total_supplier_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey
    ORDER BY total_supplier_balance DESC
    LIMIT 5
)
SELECT sh.s_name, sh.level, ss.total_sales, tr.total_supplier_balance
FROM SupplierHierarchy sh
JOIN SalesSummary ss ON sh.s_suppkey = ss.l_orderkey
JOIN TopRegions tr ON sh.s_nationkey = tr.n_regionkey
WHERE ss.total_sales > 10000
ORDER BY total_sales DESC, sh.level ASC;
