WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR) AS path
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_address, s2.s_nationkey, s2.s_acctbal,
           CONCAT(sh.path, ' -> ', s2.s_name)
    FROM supplier s2
    JOIN supplier_hierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal > sh.s_acctbal * 0.5
),
aggregated_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_mktsegment
),
ranked_orders AS (
    SELECT a.o_orderkey, a.o_totalprice, a.c_mktsegment,
           RANK() OVER (PARTITION BY a.c_mktsegment ORDER BY a.total_sales DESC) AS sales_rank
    FROM aggregated_orders a
)
SELECT s.s_name, s.s_acctbal, rh.o_orderkey, rh.c_mktsegment,
       rh.total_sales,
       CASE 
           WHEN rh.sales_rank = 1 THEN 'Top Performer'
           WHEN rh.sales_rank <= 10 THEN 'Top 10'
           ELSE 'Other'
       END AS rank_category
FROM supplier_hierarchy s
LEFT JOIN ranked_orders rh ON s.s_nationkey = rh.c_mktsegment
WHERE s.s_acctbal IS NOT NULL
AND rh.total_sales IS NOT NULL
ORDER BY s.s_acctbal DESC, rh.total_sales DESC
LIMIT 50;
