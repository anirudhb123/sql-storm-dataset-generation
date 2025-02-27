
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 
AvgPartPrice AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts_ordered
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT n.n_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
       COALESCE(AVG(ap.avg_supply_cost), 0) AS average_supply_cost,
       RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN partsupp ps ON os.distinct_parts_ordered = ps.ps_partkey
LEFT JOIN AvgPartPrice ap ON ps.ps_partkey = ap.ps_partkey
WHERE n.n_name IS NOT NULL 
GROUP BY n.n_name
HAVING SUM(os.total_revenue) > 10000
ORDER BY revenue_rank;
