WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus NOT IN ('F', 'S')
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(COALESCE(os.total_revenue, 0)) AS total_revenue,
       STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
       ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT n.n_nationkey) DESC) AS rn
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN SupplierHierarchy s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderSummary os ON s.s_suppkey = os.o_orderkey
JOIN PartSupplier ps ON ps.supplier_count > 1
GROUP BY r.r_regionkey, r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1 AND SUM(COALESCE(os.total_revenue, 0)) > 100000
ORDER BY total_revenue DESC
LIMIT 10;
