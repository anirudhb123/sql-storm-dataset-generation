WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3 -- Limit the recursion depth
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date,
           CASE WHEN SUM(o.o_totalprice) > 10000 THEN 'High Value' ELSE 'Regular' END AS customer_type
    FROM orders o
    GROUP BY o.o_custkey
),
ItemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS item_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT r.r_name,
       SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
       ns.customer_type,
       COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers,
       COALESCE(MAX(os.last_order_date), '2100-01-01') AS latest_order_date
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN OrderStats ns ON ns.o_custkey = s.s_suppkey
LEFT JOIN ItemStats os ON os.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = s.s_suppkey)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
GROUP BY r.r_name, ns.customer_type
HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
   AND r.r_name NOT LIKE '%west%' -- Exclude specific regions
ORDER BY total_supply_cost DESC NULLS LAST;
