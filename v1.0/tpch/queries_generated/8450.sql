WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
order_summary AS (
    SELECT COUNT(*) AS total_orders, 
           SUM(o.o_totalprice) AS total_revenue, 
           AVG(o.o_totalprice) AS average_order_value,
           o.o_orderstatus
    FROM ranked_orders o
    WHERE o.order_rank <= 100
    GROUP BY o.o_orderstatus
),
supplier_part_details AS (
    SELECT p.p_name, s.s_name, ps.ps_supplycost, ps.ps_availqty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0 AND ps.ps_supplycost < 200.00
)
SELECT os.o_orderstatus, os.total_orders, os.total_revenue, os.average_order_value, 
       sp.p_name, sp.s_name, sp.ps_supplycost, sp.ps_availqty
FROM order_summary os
JOIN supplier_part_details sp ON os.o_orderstatus = 
    CASE 
        WHEN os.o_orderstatus = 'O' THEN 'S' 
        WHEN os.o_orderstatus = 'F' THEN 'S' 
        ELSE 'C' 
    END
ORDER BY os.total_orders DESC, os.average_order_value ASC;
