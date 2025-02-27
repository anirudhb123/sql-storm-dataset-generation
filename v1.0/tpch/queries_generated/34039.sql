WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
order_line_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name AS nation_name, 
       COALESCE(sh.level, 0) AS supplier_level,
       COUNT(DISTINCT so.o_orderkey) AS total_orders,
       SUM(os.total_revenue) AS total_revenue,
       ns.supplier_count
FROM nation n
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN ranked_orders so ON so.price_rank <= 5 AND so.o_orderkey IN (SELECT l_orderkey FROM lineitem)
LEFT JOIN order_line_summary os ON os.l_orderkey = so.o_orderkey
LEFT JOIN nation_supplier ns ON ns.n_nationkey = n.n_nationkey
WHERE ns.supplier_count IS NOT NULL
GROUP BY n.n_name, sh.level, ns.supplier_count
ORDER BY total_revenue DESC, nation_name;
