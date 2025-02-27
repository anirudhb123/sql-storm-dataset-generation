WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT p.p_partkey, s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, s.s_suppkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(os.total_revenue) AS region_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey
),
FinalReport AS (
    SELECT ch.c_name, ch.level, tr.r_name,
           COALESCE(SUM(s.total_supply_cost), 0) AS supplier_cost,
           COALESCE(SUM(os.total_revenue), 0) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank
    FROM CustomerHierarchy ch
    LEFT JOIN TopRegions tr ON ch.c_nationkey = tr.r_regionkey
    LEFT JOIN SupplierStats s ON ch.c_nationkey = s.s_suppkey
    LEFT JOIN OrderStats os ON ch.c_custkey = os.o_orderkey
    GROUP BY ch.c_name, ch.level, tr.r_name
)
SELECT *
FROM FinalReport
WHERE revenue_rank <= 5
ORDER BY level, revenue DESC;
