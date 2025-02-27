WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
  
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.level < 5
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT
    n.n_name AS nation,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT cos.c_custkey) AS customer_count,
    SUM(cos.total_spent) AS total_customer_spent,
    AVG(cos.total_orders) AS avg_orders_per_customer
FROM nation n
LEFT JOIN supplier_stats ss ON n.n_nationkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = ss.s_suppkey)
LEFT JOIN customer_order_summary cos ON n.n_nationkey = cos.c_nationkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1 OR SUM(cos.total_spent) IS NULL
ORDER BY nation
LIMIT 10 OFFSET (SELECT COUNT(*) FROM nation) % 5;
