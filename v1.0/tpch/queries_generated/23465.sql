WITH RECURSIVE supplier_hierarchy AS (
    SELECT s1.s_suppkey, s1.s_name, s1.s_acctbal, 1 AS level
    FROM supplier s1
    WHERE s1.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s2 ON ps.ps_partkey = s2.s_suppkey
    WHERE sh.level < 5
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 100 AND ps.ps_supplycost IS NOT NULL
),
region_customer AS (
    SELECT r.r_regionkey, r.r_name, SUM(cs.total_spent) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer_summary cs ON n.n_nationkey = cs.c_custkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, p.p_name, ps.ps_availqty, cs.total_orders,
       CASE WHEN cs.total_spent IS NULL THEN 'No purchases' ELSE CONCAT('Spent: ', cs.total_spent) END AS purchase_summary,
       MAX(CASE WHEN cs.order_rank = 1 THEN cs.total_orders ELSE 0 END) OVER (PARTITION BY r.r_regionkey) AS top_orders_in_region,
       COALESCE(AVG(ps.ps_supplycost), 0) AS average_supply_cost
FROM region_customer rc
LEFT JOIN part_supplier ps ON ps.ps_availqty < 200
LEFT JOIN customer_summary cs ON cs.total_orders = (
    SELECT MAX(total_orders)
    FROM customer_summary
    WHERE order_rank = 1
)
JOIN region r ON rc.total_revenue = rc.total_revenue
ORDER BY r.r_name, p.p_name
LIMIT 10 OFFSET 5;
