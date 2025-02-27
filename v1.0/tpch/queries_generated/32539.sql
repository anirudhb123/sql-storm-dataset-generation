WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, c_mktsegment, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, c.c_mktsegment, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal > ch.c_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RegionNation AS (
    SELECT r.r_name, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT rh.c_name, rh.level, od.total_revenue, ss.total_available, 
       ss.avg_supply_cost, rn.r_name, rn.n_name,
       CASE WHEN od.total_revenue IS NULL THEN 'No Revenue' ELSE 'Revenue Exists' END AS revenue_status
FROM CustomerHierarchy rh
FULL OUTER JOIN OrderDetails od ON rh.c_custkey = od.o_orderkey
JOIN SupplierStats ss ON ss.ps_partkey = (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = (SELECT s_suppkey FROM supplier WHERE s_nationkey = rh.c_nationkey LIMIT 1))
JOIN RegionNation rn ON rn.n_name = (SELECT n_name FROM nation WHERE n_nationkey = rh.c_nationkey)
WHERE rh.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
ORDER BY rh.level DESC, od.total_revenue DESC NULLS LAST;
