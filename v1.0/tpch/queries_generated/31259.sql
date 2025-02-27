WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 
           CAST(s_suppkey AS varchar(50)) AS path, 
           1 AS level
    FROM supplier
    WHERE s_acctbal > 0

    UNION ALL

    SELECT ps.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           CONCAT(sh.path, '->', CAST(ps.ps_partkey AS varchar(50))) AS path, 
           sh.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN supplier_hierarchy sh ON sh.s_suppkey = ps.ps_suppkey
),

aggregated_orders AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS customer_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),

nation_summary AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           SUM(s.s_acctbal) AS total_balance,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT n.n_name,
       s.total_balance,
       n.supplier_count,
       a.total_revenue,
       ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY a.total_revenue DESC) AS rank,
       CASE
           WHEN a.total_revenue IS NULL THEN 'No Revenue'
           WHEN a.total_revenue > 0 THEN 'Positive Revenue'
           ELSE 'Negative Revenue'
       END AS revenue_status
FROM nation_summary n
LEFT JOIN aggregated_orders a ON n.n_nationkey = a.o_orderkey
LEFT JOIN supplier_hierarchy s ON n.n_nationkey = s.s_nuppkey
WHERE n.total_balance IS NOT NULL
  AND (n.supplier_count > 0 OR a.total_revenue IS NOT NULL)
ORDER BY s.total_balance DESC, rank;
