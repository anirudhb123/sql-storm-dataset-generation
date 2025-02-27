WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey
),
aggregated_orders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
customer_orders AS (
    SELECT ch.c_custkey, ch.c_name, ao.total_spent, ao.order_count, so.total_available, so.avg_supply_cost
    FROM customer_hierarchy ch
    JOIN aggregated_orders ao ON ch.c_custkey = ao.o_custkey
    LEFT JOIN supplier_info so ON so.total_available > 0
)
SELECT co.c_name, co.total_spent, co.order_count, COALESCE(co.total_available, 0) AS total_available,
       COALESCE(co.avg_supply_cost, 0.00) AS avg_supply_cost,
       RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
FROM customer_orders co
WHERE co.order_count > 5
ORDER BY spending_rank;
