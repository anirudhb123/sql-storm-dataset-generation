
WITH RECURSIVE regional_info AS (
    SELECT r_regionkey, r_name, n_name, 1 AS level
    FROM region
    JOIN nation ON r_regionkey = n_regionkey
    WHERE n_name IS NOT NULL
    UNION ALL
    SELECT r.r_regionkey, r.r_name, n.n_name, ri.level + 1
    FROM regional_info ri
    JOIN nation n ON ri.n_name = n.n_name
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ri.level < 5
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
sub_query AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
final_analysis AS (
    SELECT s.s_name, COUNT(DISTINCT o.o_orderkey) AS order_count, AVG(s.total_acctbal) AS avg_acctbal,
           MAX(o.order_revenue) AS max_revenue
    FROM supplier_summary s
    LEFT JOIN sub_query o ON s.s_suppkey = o.o_orderkey
    GROUP BY s.s_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 0
    ORDER BY max_revenue DESC
)
SELECT sr.r_name, fa.s_name, fa.order_count, 
       CASE 
           WHEN fa.avg_acctbal IS NULL THEN 'Unknown' 
           ELSE CAST(fa.avg_acctbal AS VARCHAR) 
       END AS avg_acctbal_text,
       fa.max_revenue
FROM final_analysis fa
FULL OUTER JOIN regional_info sr ON fa.s_name LIKE '%' || sr.n_name || '%'
WHERE (fa.max_revenue IS NOT NULL AND fa.max_revenue > 1000)
   OR (sr.level > 1 AND fa.order_count IS NULL)
ORDER BY sr.r_name DESC, fa.order_count ASC;
