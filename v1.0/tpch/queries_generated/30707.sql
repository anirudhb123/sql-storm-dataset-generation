WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.level + 1) * 500
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),
OrderSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplierStats AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT r.r_name, ps.total_available_qty, os.total_spent, os.total_orders,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY os.total_spent DESC) AS rank,
       COALESCE(sh.level, -1) AS supplier_level
FROM RegionStats r
JOIN PartSupplierStats ps ON r.nation_count > 0
JOIN OrderSummary os ON os.total_orders > 10
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = os.c_custkey
WHERE ps.total_available_qty > 100
ORDER BY r.r_name, os.total_spent DESC;
