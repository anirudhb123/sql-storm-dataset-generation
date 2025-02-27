WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 30000 AND sh.depth < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderstatus, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1997-12-31'
),
LineItemAggregates AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierPerformance AS (
    SELECT sh.s_suppkey, sh.s_name, COUNT(DISTINCT co.o_orderkey) AS total_orders,
           SUM(COALESCE(l.total_revenue, 0)) AS total_revenue
    FROM SupplierHierarchy sh
    LEFT JOIN CustomerOrders co ON sh.s_nationkey = co.o_orderkey
    LEFT JOIN LineItemAggregates l ON co.o_orderkey = l.l_orderkey
    GROUP BY sh.s_suppkey, sh.s_name
),
BestSupplier AS (
    SELECT s.s_suppkey, s.s_name, sp.total_orders, sp.total_revenue,
           RANK() OVER (ORDER BY sp.total_revenue DESC) AS revenue_rank
    FROM supplier s
    JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
)
SELECT b.s_suppkey, b.s_name, b.total_orders, b.total_revenue
FROM BestSupplier b
WHERE b.revenue_rank <= 10
ORDER BY b.total_revenue DESC;