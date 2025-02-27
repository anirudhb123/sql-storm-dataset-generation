WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
           COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           SUM(o.o_totalprice) AS total_order_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' OR o.o_orderdate IS NULL
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT nh.n_name AS nation_name,
       COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
       COALESCE(cs.total_order_value, 0) AS total_order_value,
       (COALESCE(ss.total_supply_cost, 0) - COALESCE(cs.total_order_value, 0)) AS balance
FROM nation_hierarchy nh
LEFT JOIN supplier_summary ss ON nh.n_nationkey = ss.s_nationkey
LEFT JOIN customer_summary cs ON nh.n_nationkey = cs.c_nationkey
WHERE (ss.total_supply_cost IS NOT NULL OR cs.total_order_value IS NOT NULL)
ORDER BY balance DESC
LIMIT 10;
