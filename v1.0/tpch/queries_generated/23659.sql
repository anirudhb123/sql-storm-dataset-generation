WITH RECURSIVE suppliers_with_scores AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(CASE 
                   WHEN p.p_size < 10 THEN 1 
                   ELSE 0 
               END * ps.ps_availqty) AS low_size_score,
           SUM(CASE 
                   WHEN p.p_size >= 10 AND p.p_size < 20 THEN 1 
                   ELSE 0 
               END * ps.ps_availqty) AS medium_size_score,
           SUM(CASE 
                   WHEN p.p_size >= 20 THEN 1 
                   ELSE 0 
               END * ps.ps_availqty) AS high_size_score,
           COUNT(DISTINCT o.o_orderkey) AS orders_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_total_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE s.s_acctbal IS NOT NULL OR (s.s_comment LIKE '%special%' AND s.s_phone IS NOT NULL)
    GROUP BY s.s_suppkey, s.s_name

    UNION ALL

    SELECT NULL, 'Aggregated', 
           SUM(low_size_score), 
           SUM(medium_size_score), 
           SUM(high_size_score),
           SUM(orders_count), 
           SUM(supplier_total_value)
    FROM suppliers_with_scores
    WHERE low_size_score > 0 OR medium_size_score > 0 OR high_size_score > 0
)

SELECT r.r_name AS region, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count, 
       SUM(COALESCE(ss.low_size_score, 0)) AS total_low_size_score,
       SUM(COALESCE(ss.medium_size_score, 0)) AS total_medium_size_score,
       SUM(COALESCE(ss.high_size_score, 0)) AS total_high_size_score,
       MAX(ss.orders_count) AS max_orders,
       MIN(ss.supplier_total_value) AS min_supplier_value
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN suppliers_with_scores ss ON ss.s_suppkey IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(n.n_nationkey) > (SELECT COUNT(*) FROM nation) / 3 
   AND SUM(ss.high_size_score) IS NOT NULL
ORDER BY region ASC
LIMIT 5;
