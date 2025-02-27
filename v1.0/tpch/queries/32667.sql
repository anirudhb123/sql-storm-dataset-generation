
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey
),
customer_revenue AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(os.total_revenue), 0) AS total_revenue
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
nation_revenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(cr.total_revenue) AS nation_revenue
    FROM nation n
    LEFT JOIN customer_revenue cr ON n.n_nationkey = cr.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(nr.nation_revenue, 0) AS nation_total_revenue,
    SUM(sh.s_acctbal) AS supplier_acctbal_total
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN nation_revenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_suppkey
GROUP BY r.r_name, n.n_name, nr.nation_revenue
HAVING COALESCE(nr.nation_revenue, 0) > 0
ORDER BY region_name, nation_name;
