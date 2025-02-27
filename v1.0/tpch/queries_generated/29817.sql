WITH supplier_details AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           n.n_name AS nation_name, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost) AS total_supplycost,
           STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), customer_orders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           STRING_AGG(DISTINCT CONCAT('OrderID: ', o.o_orderkey, ' (', o.o_orderdate, ')'), '; ') AS orders_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT sd.s_name, 
       sd.nation_name, 
       sd.part_count, 
       sd.total_supplycost, 
       sd.part_names,
       co.c_name, 
       co.order_count, 
       co.total_spent, 
       co.orders_info
FROM supplier_details sd
JOIN customer_orders co ON sd.part_count > 0 AND co.order_count > 0
ORDER BY sd.total_supplycost DESC, co.total_spent DESC;
