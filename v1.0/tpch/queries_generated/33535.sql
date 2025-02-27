WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE ps.ps_availqty < sc.ps_availqty
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
      AND l.l_shipdate < current_date
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT regions.r_name AS region_name,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       AVG(os.total_sales) AS avg_order_value,
       SUM(CASE 
               WHEN os.total_sales > 1000 THEN 1 
               ELSE 0 
           END) AS high_value_orders
FROM region regions
LEFT JOIN nation n ON regions.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN order_summary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN supply_chain sc ON o.o_orderkey = sc.ps_partkey
GROUP BY regions.r_name
ORDER BY total_orders DESC, avg_order_value DESC
LIMIT 10;
