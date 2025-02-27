WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
customer_vip AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
nations_with_high_supplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS high_supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY n.n_nationkey, n.n_name
),
orders_summary AS (
    SELECT o.o_orderstatus, COUNT(*) AS order_count, SUM(o.o_totalprice) AS total_revenue,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY o.o_orderstatus
)
SELECT p.p_name, p.p_retailprice, s.s_name, sh.level AS supplier_level,
       c.c_name AS vip_customer, c.c_acctbal AS vip_acctbal,
       n.high_supplier_count, os.order_count, os.total_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN customer_vip c ON sh.level = 1 AND c.rank <= 5
LEFT JOIN nations_with_high_supplier n ON s.s_nationkey = n.n_nationkey
LEFT JOIN orders_summary os ON os.o_orderstatus = 'O'
WHERE p.p_retailprice IS NOT NULL AND p.p_size < 100
ORDER BY p.p_name, os.total_revenue DESC
LIMIT 50;
