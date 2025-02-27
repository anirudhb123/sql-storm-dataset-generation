WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT nh.n_name, ss.s_name, c.customer_spent, ss.total_available,
       CASE 
           WHEN c.order_count > 10 THEN 'High Volume'
           WHEN c.order_count BETWEEN 5 AND 10 THEN 'Medium Volume'
           ELSE 'Low Volume' 
       END AS customer_classification
FROM nation_hierarchy nh
FULL OUTER JOIN supplier_stats ss ON nh.n_nationkey = ss.s_suppkey
LEFT JOIN (
    SELECT c.c_custkey AS customer_key, 
           SUM(o.o_totalprice) AS customer_spent, 
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
) c ON c.customer_key = ss.s_suppkey
WHERE ss.total_available IS NOT NULL
OR c.customer_spent IS NOT NULL
ORDER BY nh.n_name, ss.avg_supply_cost DESC
LIMIT 100;
