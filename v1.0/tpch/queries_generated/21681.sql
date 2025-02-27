WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '2022-01-01'
    GROUP BY o.o_orderkey
), nation_stats AS (
    SELECT n.n_nationkey, AVG(c.c_acctbal) AS avg_acctbal,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
), expensive_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > 500.00 AND p.p_size BETWEEN 5 AND 10
)
SELECT n.n_name,
       ns.avg_acctbal,
       ns.distinct_suppliers,
       COALESCE(os.total_revenue, 0) AS total_order_revenue,
       COALESCE(ep.p_name, 'No Expensive Part') AS expensive_part,
       sh.level,
       CASE 
           WHEN ns.avg_acctbal IS NULL THEN 'Unknown Region'
           ELSE 'Known Region'
       END AS region_status
FROM nation n
JOIN nation_stats ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN order_summary os ON ns.distinct_suppliers = os.o_orderkey
LEFT JOIN expensive_parts ep ON ep.p_partkey = os.o_orderkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE ns.distinct_suppliers > 0
ORDER BY n.n_name, level DESC
FETCH FIRST 100 ROWS ONLY;
