WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal < 10000
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 10000
),
OrderSummary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS lineitem_count, SUM(l.l_extendedprice) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name, RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS supplier_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ch.c_name, ch.c_acctbal, ss.total_avail_qty, ss.total_supply_cost, os.total_revenue,
       ni.n_name, ni.supplier_rank
FROM CustomerHierarchy ch
LEFT JOIN SupplierStats ss ON ss.total_avail_qty > ch.c_acctbal
LEFT JOIN OrderSummary os ON os.lineitem_count > 1
JOIN NationInfo ni ON ni.supplier_rank < 3
WHERE ss.total_supply_cost IS NOT NULL AND (ch.c_acctbal IS NULL OR ch.c_acctbal > 5000)
ORDER BY ch.c_acctbal DESC, ss.total_supply_cost ASC;
