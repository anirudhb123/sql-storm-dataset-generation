WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS supplier_comment,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS supplier_comment,
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 3
), 
order_stats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
total_revenue_by_supplier AS (
    SELECT ps.ps_suppkey, SUM(o.total_revenue) AS total_rev
    FROM partsupp ps
    JOIN order_stats o ON ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l WHERE l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o WHERE o.o_orderstatus = 'O')
    )
    GROUP BY ps.ps_suppkey
)
SELECT s.s_name, s.s_acctbal, s.supplier_comment, 
       COALESCE(t.total_rev, 0) AS total_revenue,
       ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS ranking
FROM supplier_hierarchy s
LEFT JOIN total_revenue_by_supplier t ON s.s_suppkey = t.ps_suppkey
WHERE t.total_rev IS NOT NULL OR s.s_acctbal > 1000
ORDER BY s.s_nationkey, ranking
LIMIT 50;
