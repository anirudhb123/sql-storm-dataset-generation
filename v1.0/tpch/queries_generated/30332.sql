WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s2 ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
nation_supplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT ns.n_name,
       ns.supplier_count,
       os.total_revenue,
       ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY os.total_revenue DESC) AS rank_per_nation,
       COALESCE(AVG(os.total_revenue) OVER (PARTITION BY ns.n_name), 0) AS avg_revenue_per_nation,
       sh.level
FROM nation_supplier ns
LEFT JOIN order_summary os ON ns.n_name = 'FRANCE' AND os.total_revenue > (
    SELECT AVG(total_revenue) FROM order_summary
)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ns.supplier_count
WHERE ns.supplier_count IS NOT NULL
ORDER BY ns.n_name, rank_per_nation;
