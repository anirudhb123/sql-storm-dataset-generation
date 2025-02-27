WITH recursive_part AS (
    SELECT p_partkey, p_name, p_retailprice, p_comment,
           ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) as rn
    FROM part
    WHERE p_size BETWEEN 10 AND 20 
      AND p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size < 10)
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal, AVG(s.s_acctbal) AS avg_acctbal 
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           (SELECT COUNT(DISTINCT o.o_orderkey) 
            FROM orders o WHERE o.o_custkey = c.c_custkey) AS order_count 
    FROM customer c 
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
final_results AS (
    SELECT p.p_name, ns.n_name, hc.c_name, hc.order_count, 
           CASE WHEN hc.order_count = 0 THEN NULL ELSE hc.c_acctbal / hc.order_count END AS avg_order_value
    FROM recursive_part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN nation_stats ns ON ps.ps_suppkey = (SELECT MIN(s.s_suppkey) 
                                              FROM supplier s WHERE s.s_nationkey = ns.n_nationkey)
    JOIN high_value_customers hc ON ns.supplier_count > 5 
    WHERE p.rn <= 3 AND (p.p_comment IS NULL OR p.p_comment LIKE '%specific%') 
      AND ns.total_acctbal IS NOT NULL
)
SELECT f.p_name, f.n_name, f.c_name, f.order_count, f.avg_order_value, 
       CASE 
           WHEN f.avg_order_value IS NULL THEN 'No Orders' 
           WHEN f.avg_order_value > 1000 THEN 'High Value'
           ELSE 'Regular'
       END AS customer_value_status
FROM final_results f
ORDER BY f.n_name ASC, f.c_name DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
