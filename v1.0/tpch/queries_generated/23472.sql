WITH RECURSIVE top_nations AS (
    SELECT n_nationkey, n_name, n_regionkey, ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) as rn
    FROM nation
), 
supplier_summary AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal, COUNT(*) AS supplier_count, 
           CASE 
               WHEN SUM(s_acctbal) > 100000 THEN 'High Value'
               WHEN SUM(s_acctbal) BETWEEN 50000 AND 100000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS value_segment
    FROM supplier
    GROUP BY s_nationkey
),
order_summary AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
           COUNT(DISTINCT o_orderkey) OVER (PARTITION BY o_custkey) AS order_count
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey, o_custkey
)
SELECT ps_partkey, p_name, 
       COALESCE(CAST(SUM(l_extendedprice * (1 - l_discount)) AS decimal(12, 2)), 0) AS total_revenue,
       COUNT(DISTINCT lineitem.l_suppkey) AS supplier_count,
       STRING_AGG(s_name, ', ') AS suppliers,
       r_name
FROM part
LEFT JOIN partsupp ON p_partkey = ps_partkey
LEFT JOIN supplier ON ps_suppkey = s_suppkey
LEFT JOIN lineitem ON l_partkey = p_partkey
LEFT JOIN orders ON l_orderkey = o_orderkey
LEFT JOIN customer ON o_custkey = c_custkey
JOIN region r ON n_regionkey = r_regionkey
JOIN top_nations n ON n.n_nationkey = s_nationkey
JOIN supplier_summary ss ON ss.s_nationkey = n.n_nationkey 
WHERE ss.value_segment = 'High Value'
  AND (l_shipdate IS NULL OR l_shipdate > '1995-01-01')
  AND p_retailprice BETWEEN 10 AND 100
GROUP BY ps_partkey, p_name, r_name
HAVING total_revenue > (SELECT AVG(total_acctbal) FROM supplier_summary WHERE value_segment = 'Medium Value')
ORDER BY total_revenue DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
