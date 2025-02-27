WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    INNER JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartPerformance AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > 10000
),
RecentLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, ns.supplier_count, ns.total_acctbal,
       pp.p_name, pp.total_supply_cost,
       hl.o_orderkey, hl.o_totalprice,
       rli.total_revenue, rli.item_count,
       COALESCE(sh.level, 0) AS supplier_level
FROM NationSummary ns
JOIN PartPerformance pp ON pp.total_supply_cost > 10000
LEFT JOIN HighValueOrders hl ON hl.order_rank <= 5
LEFT JOIN RecentLineItems rli ON rli.l_orderkey = hl.o_orderkey
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
WHERE ns.total_acctbal IS NOT NULL
ORDER BY ns.supplier_count DESC, pp.total_supply_cost DESC;
