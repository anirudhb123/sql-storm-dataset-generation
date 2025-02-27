WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 5
),
aggregated_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
top_part AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING COUNT(ps.ps_suppkey) > 5
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(ao.total_revenue) AS total_order_revenue,
    MAX(COALESCE(sh.level, 0)) AS supplier_level,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN aggregated_orders ao ON s.s_suppkey = ao.o_orderkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN top_part p ON p.supplier_count > 0
GROUP BY r.r_name, n.n_name, s.s_name
HAVING SUM(COALESCE(ao.total_revenue, 0)) > 10000
ORDER BY total_order_revenue DESC, r.r_name;
