WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, sh.level + 1 
    FROM partsupp ps
    JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 100
),

ranked_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),

customer_stats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)

SELECT 
    p.p_name,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(cs.total_spent, 0.00) AS total_spent,
    sh.level AS supplier_level,
    ro.sales_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN customer_stats cs ON cs.total_spent > 10000
LEFT JOIN nation n ON sh.s_suppkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN ranked_orders ro ON ro.total_sales > 50000
WHERE p.p_retailprice BETWEEN 10 AND 100
  AND (n.n_name IS NOT NULL OR cs.order_count IS NOT NULL)
ORDER BY total_spent DESC, p.p_name;
