WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    
    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.depth + 1
    FROM supplier_hierarchy sh
    JOIN supplier s2 ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal < (SELECT AVG(s3.s_acctbal) FROM supplier s3 WHERE s3.s_nationkey = s2.s_nationkey)
      AND sh.depth < 5
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_item_count,
           MAX(l.l_shipdate) AS latest_shipdate
    FROM lineitem l
    GROUP BY l.l_orderkey
),
interesting_orders AS (
    SELECT o.o_orderkey, 
           COALESCE(ls.total_revenue, 0) AS total_revenue,
           o.o_orderstatus,
           CASE 
               WHEN ls.total_revenue IS NOT NULL AND ls.total_revenue > 10000 THEN 'High'
               WHEN ls.total_revenue IS NULL THEN 'Null'
               ELSE 'Low'
           END AS revenue_category,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY ls.total_revenue DESC) AS revenue_rank
    FROM orders o
    LEFT JOIN lineitem_summary ls ON o.o_orderkey = ls.l_orderkey
)
SELECT ns.n_name,
       COALESCE(SUM(DISTINCT o.total_revenue), 0) AS total_revenue_by_nation,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       STRING_AGG(DISTINCT o.revenue_category || ' ordered at rank ' || o.revenue_rank, ', ' ORDER BY o.revenue_rank) AS order_revenue_summary
FROM nation ns
LEFT JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN interesting_orders o ON o.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.15
    INTERSECT
    SELECT o2.o_orderkey
    FROM orders o2
    WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '90 days'
)
GROUP BY ns.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY total_revenue_by_nation DESC
LIMIT 10 OFFSET 5;
