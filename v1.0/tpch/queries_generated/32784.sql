WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),

customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),

high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.total_orders, c.total_spent
    FROM customer_orders c
    WHERE c.total_spent > 10000
),

order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),

supplier_sales AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),

result AS (
    SELECT r.r_name, 
           COUNT(DISTINCT h.c_custkey) AS high_value_customer_count, 
           SUM(s.total_sales) AS total_supplier_sales,
           MAX(s.s_acctbal) AS max_supplier_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer_orders h ON n.n_nationkey = h.c_nationkey
    JOIN supplier_sales s ON s.ps_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
    LEFT JOIN supplier_hierarchy sh ON s.ps_suppkey = sh.s_suppkey
    GROUP BY r.r_name
)

SELECT r_name, high_value_customer_count, total_supplier_sales, max_supplier_acctbal
FROM result
WHERE high_value_customer_count > 5
ORDER BY total_supplier_sales DESC
LIMIT 10;
