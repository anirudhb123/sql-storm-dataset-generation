WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN region_hierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_analysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(*) AS total_items, AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
final_result AS (
    SELECT c.c_name, COALESCE(o.order_count, 0) AS order_count, COALESCE(o.total_spent, 0) AS total_spent,
           s.total_supply_cost, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY COALESCE(o.total_spent, 0) DESC) AS order_rank
    FROM customer_orders o
    JOIN customer c ON c.c_custkey = o.c_custkey
    LEFT JOIN supplier_summary s ON s.s_name LIKE '%' || SUBSTRING(c.c_name FROM 1 FOR 4) || '%'
)
SELECT r.r_name, COUNT(DISTINCT fr.c_name) AS customer_count, 
       AVG(fr.order_count) AS avg_orders, 
       SUM(fr.total_spent) AS total_spent_per_region,
       MAX(fr.total_supply_cost) AS max_supply_cost
FROM region_hierarchy r
JOIN final_result fr ON r.r_regionkey = fr.c_custkey % 5
GROUP BY r.r_name
HAVING AVG(fr.order_count) > 2 AND SUM(fr.total_spent) > 1000
ORDER BY r.r_name;
