WITH high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
    )
),
supplier_performance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
order_line_statistics AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT r.r_name, 
       SUM(COALESCE(ho.o_totalprice, 0)) AS total_order_value, 
       COUNT(DISTINCT ol.l_orderkey) AS total_orders, 
       SUM(sp.total_supply_cost) AS total_supplier_cost
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN high_value_orders ho ON n.n_nationkey = ho.c_nationkey
LEFT JOIN order_line_statistics ol ON ho.o_orderkey = ol.l_orderkey
LEFT JOIN supplier_performance sp ON sp.ps_partkey IN (
    SELECT ps_partkey 
    FROM partsupp 
    WHERE ps_supplycost > 100
)
GROUP BY r.r_name
HAVING SUM(COALESCE(ho.o_totalprice, 0)) > 100000
ORDER BY total_order_value DESC;
