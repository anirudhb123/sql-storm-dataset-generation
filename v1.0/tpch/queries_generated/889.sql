WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
), nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), orders_with_discount AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)

SELECT 
    nd.n_name AS nation_name,
    COUNT(DISTINCT owd.o_orderkey) AS total_orders,
    SUM(owd.order_value) AS total_order_value,
    ts.total_value AS supplier_total_value
FROM orders_with_discount owd
LEFT JOIN top_suppliers ts ON owd.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_suppkey IN (SELECT s_suppkey FROM top_suppliers)
)
JOIN nation_details nd ON owd.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_nationkey = nd.n_nationkey
)
WHERE owd.order_rank = 1 AND ts.total_value IS NOT NULL
GROUP BY nd.n_name, ts.total_value
HAVING SUM(owd.order_value) > 1000
ORDER BY total_orders DESC, total_order_value DESC;
