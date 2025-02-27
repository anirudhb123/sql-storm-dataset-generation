WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
PartOrderStats AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
    GROUP BY c.c_custkey, c.c_name
)
SELECT rh.s_name AS supplier_name, pos.p_name AS part_name, pos.total_revenue, co.total_orders, co.total_spent
FROM SupplierHierarchy rh
JOIN PartOrderStats pos ON rh.s_nationkey IN (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_nationkey IN (
        SELECT DISTINCT s_nationkey FROM supplier WHERE s_suppkey = rh.s_suppkey
    )
)
JOIN CustomerOrders co ON co.total_orders > 5 AND co.avg_spent > 500
WHERE pos.revenue_rank <= 10
ORDER BY pos.total_revenue DESC, co.total_spent DESC
LIMIT 10;
