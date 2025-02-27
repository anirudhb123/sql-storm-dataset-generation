WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, os.total_revenue,
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
    JOIN orders o ON o.o_orderkey = os.o_orderkey
    WHERE os.total_revenue > 10000
)
SELECT DISTINCT n.n_name, COALESCE(SUM(DISTINCT sh.s_suppkey), 0) AS suppliers_count,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       AVG(ps.ps_supplycost) AS avg_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN HighValueOrders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_orderkey) 
LEFT JOIN PartSupplier ps ON o.o_orderkey = ps.p_partkey
WHERE r.r_name IS NOT NULL AND ps.rn = 1
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY suppliers_count DESC, order_count DESC;