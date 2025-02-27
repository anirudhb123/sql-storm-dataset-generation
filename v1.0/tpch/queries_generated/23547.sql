WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
TopOrders AS (
    SELECT od.o_orderkey, od.total_revenue
    FROM OrderDetails od 
    WHERE od.revenue_rank <= 10
    ORDER BY od.total_revenue DESC
),
SupplierStats AS (
    SELECT sh.s_nationkey, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
           SUM(sh.s_acctbal) AS total_acctbal
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT r.r_name, ss.supplier_count, ss.total_acctbal,
       COALESCE(TO_CHAR(MAX(to_char(od.o_orderkey) || ':' || CAST(od.total_revenue AS varchar)), 'FM9G999G999D00'), 'No Orders') AS max_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON ss.s_nationkey = n.n_nationkey
LEFT JOIN TopOrders od ON od.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_acctbal IS NULL OR c.c_acctbal < 500
    )
)
WHERE r.r_name LIKE '%East%'
GROUP BY r.r_name, ss.supplier_count, ss.total_acctbal
ORDER BY r.r_name, ss.total_acctbal DESC;
