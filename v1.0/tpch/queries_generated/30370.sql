WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),

RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),

SupplierPartStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

TopSuppliers AS (
    SELECT sh.s_name, sh.s_acctbal, sh.level, 
           (SELECT COUNT(*) FROM order_count WHERE o_custkey = c.c_custkey) AS total_orders,
           ROW_NUMBER() OVER (ORDER BY sh.s_acctbal DESC) AS rank
    FROM SupplierHierarchy sh
    JOIN customer c ON sh.s_nationkey = c.c_nationkey
    WHERE sh.s_acctbal IS NOT NULL
)

SELECT 
    p.p_name,
    ps.total_availqty,
    ps.avg_supplycost,
    COALESCE(ts.s_name, 'Unknown') AS supplier_name,
    ts.total_orders,
    ts.level
FROM part p
LEFT JOIN SupplierPartStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN TopSuppliers ts ON ts.level <= 2
WHERE p.p_size > 10
AND p.p_brand LIKE 'Brand%'
AND EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_partkey = p.p_partkey 
    AND l.l_discount > 0.1
)
ORDER BY ps.total_availqty DESC, ts.total_orders DESC
LIMIT 100;
