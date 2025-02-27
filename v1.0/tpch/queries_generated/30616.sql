WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal
    FROM customer
    WHERE c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > ch.c_acctbal
),
SupplierMetrics AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           MAX(l.l_shipdate) AS last_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'P')
    GROUP BY o.o_orderkey, o.o_orderstatus
),
RegionCosts AS (
    SELECT r.r_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
)
SELECT r.r_name, r.revenue, r.order_count, sm.total_avail_qty, sm.avg_supply_cost,
       ch.c_name, ch.c_acctbal
FROM RegionCosts r
LEFT JOIN SupplierMetrics sm ON r.order_count > 0
LEFT JOIN CustomerHierarchy ch ON ch.c_acctbal <= 20000
WHERE r.revenue > (SELECT AVG(revenue) FROM RegionCosts)
ORDER BY r.revenue DESC, sm.avg_supply_cost ASC
LIMIT 10;
