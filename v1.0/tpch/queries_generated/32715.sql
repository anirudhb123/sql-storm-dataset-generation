WITH RECURSIVE price_summary AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS brand_rank
    FROM part
),
suppliers_summary AS (
    SELECT s.s_nationkey, AVG(s.s_acctbal) AS avg_acctbal, COUNT(s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
nation_performance AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(ss.avg_acctbal, 0) AS avg_acctbal,
           COALESCE(ss.supplier_count, 0) AS supplier_count,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM nation n
    LEFT JOIN suppliers_summary ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
    GROUP BY n.n_nationkey, n.n_name
),
final_summary AS (
    SELECT np.n_name, np.avg_acctbal, np.supplier_count, np.total_orders,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_returns
    FROM nation_performance np
    LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = np.n_nationkey))
    GROUP BY np.n_name, np.avg_acctbal, np.supplier_count, np.total_orders
)
SELECT fn.n_name, fn.avg_acctbal, fn.supplier_count, fn.total_orders, fn.total_returns,
       CASE 
           WHEN fn.total_orders > 100 THEN 'High Performance'
           ELSE 'Low Performance'
       END AS performance_category
FROM final_summary fn
WHERE fn.avg_acctbal IS NOT NULL AND fn.total_orders > 0
ORDER BY performance_category DESC, fn.total_returns DESC;
