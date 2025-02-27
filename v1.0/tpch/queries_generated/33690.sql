WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey
),

TopOrders AS (
    SELECT o.*, RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM orders o
    JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    WHERE os.total_revenue IS NOT NULL
)

SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COALESCE(SUM(lo.total_revenue), 0) AS total_revenue,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     JOIN TopOrders to ON o.o_orderkey = to.o_orderkey
     WHERE to.o_orderstatus = 'O') AS total_completed_orders,
    rh.r_name AS region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region rh ON n.n_regionkey = rh.r_regionkey
LEFT JOIN OrderSummary lo ON p.p_partkey = lo.o_orderkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY p.p_name, s.s_name, rh.r_name
HAVING SUM(ps.ps_availqty) > 100
ORDER BY total_revenue DESC NULLS LAST;
