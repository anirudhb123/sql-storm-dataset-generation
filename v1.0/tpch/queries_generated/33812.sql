WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 50000 AND sh.level < 5
),
OrderAggregates AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, cp.order_count,
           RANK() OVER (ORDER BY cp.order_count DESC) AS rank
    FROM CustomerPurchases cp
    JOIN customer c ON cp.c_custkey = c.c_custkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, n.supplier_count, n.total_account_balance,
       cr.c_name, cr.order_count,
       COALESCE(ah.total_revenue, 0) AS total_revenue
FROM NationSummary n
LEFT JOIN CustomerRanked cr ON cr.rank <= 10
LEFT JOIN (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
) ah ON ah.o_orderkey IN (
    SELECT DISTINCT l.l_orderkey
    FROM lineitem l 
    WHERE l.l_shipmode = 'AIR' AND l.l_returnflag = 'N'
)
ORDER BY n.supplier_count DESC, cr.order_count DESC
LIMIT 50;
