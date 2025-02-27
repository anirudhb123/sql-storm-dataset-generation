WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS depth, 
           NULL AS parent_suppkey, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.depth + 1, 
           sh.s_suppkey AS parent_suppkey, s.s_nationkey
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE sh.depth < 3
),
nation_stats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal, 
           AVG(s.s_acctbal) AS avg_acctbal,
           SUM(CASE WHEN s.s_acctbal > 10000 THEN 1 ELSE 0 END) AS high_balance_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT ns.n_name,
       ns.supplier_count,
       ns.total_acctbal,
       ns.avg_acctbal,
       ns.high_balance_count,
       COALESCE(sh.depth, 0) AS hierarchy_depth,
       COALESCE(string_agg(DISTINCT sh.s_name, ', '), 'No suppliers') AS suppliers
FROM nation_stats ns
LEFT JOIN supplier_hierarchy sh ON ns.supplier_count = (SELECT COUNT(*) FROM supplier WHERE supplier.s_nationkey = ns.n_nationkey)
GROUP BY ns.n_name, ns.supplier_count, ns.total_acctbal, ns.avg_acctbal, ns.high_balance_count, sh.depth
ORDER BY ns.total_acctbal DESC
FETCH FIRST 10 ROWS ONLY;
