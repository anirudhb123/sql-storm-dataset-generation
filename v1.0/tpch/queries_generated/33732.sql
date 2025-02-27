WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name = 'USA'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), top_regions AS (
    SELECT r.r_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY r.r_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT th.r_name, sh.s_name, os.total_revenue, os.order_count, 
       ROW_NUMBER() OVER (PARTITION BY th.r_name ORDER BY os.total_revenue DESC) AS revenue_rank
FROM top_regions th
JOIN supplier_hierarchy sh ON sh.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN order_summary os ON os.o_orderdate >= '2023-01-01'
WHERE os.total_revenue IS NOT NULL
ORDER BY th.r_name, revenue_rank;
