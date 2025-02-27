WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
supplier_part_details AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_supplycost,
           SUM(li.l_quantity) AS total_sold
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_supplycost
),
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * total_sold) AS total_sales_value
    FROM supplier_part_details ps
    JOIN supplier s ON ps.s_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_sales_value DESC
    LIMIT 10
)
SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus, 
       tsp.s_name, tsp.total_sales_value
FROM ranked_orders ro
JOIN top_suppliers tsp ON ro.o_orderkey IN (
    SELECT li.l_orderkey
    FROM lineitem li
    JOIN part p ON li.l_partkey = p.p_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_suppkey = tsp.s_suppkey
)
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;