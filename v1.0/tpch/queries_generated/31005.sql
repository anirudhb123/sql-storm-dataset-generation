WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND sh.level < 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(s.s_acctbal) > 1000000
),
HistoricalOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate < (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_price
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    r.r_name,
    SUM(cs.order_count) AS total_orders,
    AVG(cs.avg_order_price) AS average_price,
    MAX(th.total_acctbal) AS max_account_balance,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM TopRegions r
LEFT JOIN CustomerSummary cs ON r.r_regionkey = cs.c_nationkey
LEFT JOIN SupplierHierarchy sh ON r.r_regionkey = sh.s_nationkey
LEFT JOIN HistoricalOrders th ON th.o_orderdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
GROUP BY r.r_regionkey, r.r_name
ORDER BY total_orders DESC, max_account_balance DESC
LIMIT 10;
