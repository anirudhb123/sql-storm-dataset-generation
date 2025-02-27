WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
), 
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
), 
nation_summary AS (
    SELECT n.n_nationkey, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey
)
SELECT
    r.r_name,
    ns.customer_count,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COALESCE(SUM(os.total_revenue), 0) DESC) AS revenue_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN nation_summary ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN order_summary os ON ns.customer_count > 0
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
GROUP BY r.r_name, ns.customer_count
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY total_revenue DESC, r.r_name;
