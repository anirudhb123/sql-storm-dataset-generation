WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
order_details AS (
    SELECT o.o_orderkey, 
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT cs.c_name, cs.order_count, cs.total_spent, ss.part_count, ss.total_supply_cost,
       od.total_order_value, od.order_rank
FROM customer_orders cs
LEFT JOIN supplier_summary ss ON cs.order_count > 0
LEFT JOIN order_details od ON od.o_orderkey = cs.c_custkey
WHERE cs.total_spent IS NOT NULL
  AND (ss.total_supply_cost IS NULL OR ss.total_supply_cost > 10000)
ORDER BY cs.total_spent DESC, ss.total_supply_cost ASC;
