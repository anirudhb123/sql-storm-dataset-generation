WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice < 50 AND sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
           COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (ORDER BY SUM(os.revenue) DESC) AS rank
    FROM customer c
    JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(os.o_orderkey) > 5
)
SELECT rh.r_name, COALESCE(SUM(os.revenue), 0) AS total_revenue, 
       COUNT(DISTINCT tc.c_custkey) AS active_customers,
       COUNT(DISTINCT sh.s_suppkey) AS suppliers_count
FROM region rh
LEFT JOIN nation n ON n.n_regionkey = rh.r_regionkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o 
                                                 JOIN customer c ON o.o_custkey = c.c_custkey 
                                                 WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN top_customers tc ON tc.c_custkey = os.o_orderkey
GROUP BY rh.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) >= 10
ORDER BY total_revenue DESC, active_customers DESC;
