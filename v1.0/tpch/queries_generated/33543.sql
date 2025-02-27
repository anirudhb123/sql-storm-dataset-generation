WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
regional_summary AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer_orders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
lineitem_stats AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count, SUM(l.l_extendedprice) AS total_value,
           AVG(l.l_discount) AS avg_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name AS region_name, 
       nh.n_name AS nation_name, 
       hvc.c_name AS high_value_customer, 
       l.item_count, 
       l.total_value,
       l.avg_discount,
       COALESCE(hvc.total_spent / NULLIF(l.total_value, 0), 0) AS spending_ratio
FROM regional_summary r
JOIN nation n ON r.supplier_count > 0
JOIN nation_hierarchy nh ON nh.n_regionkey = n.n_regionkey
LEFT JOIN high_value_customers hvc ON hvc.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l))
LEFT JOIN lineitem_stats l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hvc.c_custkey)
WHERE r.total_supply_cost > 10000
ORDER BY spending_ratio DESC, r.r_name, nh.level;
