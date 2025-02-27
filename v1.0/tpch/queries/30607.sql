WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 0
),
PartSupplierStats AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 2
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus <> 'F'
    GROUP BY o.o_orderkey
)
SELECT r.r_name,
       SUM(ps.total_available_qty) AS total_availability,
       AVG(ps.average_supply_cost) AS avg_supply_cost,
       COUNT(DISTINCT os.o_orderkey) AS total_orders,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(ps.total_available_qty) DESC) AS rank
FROM TopRegions r
LEFT JOIN PartSupplierStats ps ON r.r_regionkey = ps.ps_partkey
LEFT JOIN OrderSummary os ON os.total_items > 10
GROUP BY r.r_name
HAVING COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY rank, total_availability DESC;
