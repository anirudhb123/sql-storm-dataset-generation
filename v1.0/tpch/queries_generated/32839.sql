WITH RECURSIVE high_value_orders AS (
    SELECT o_orderkey, o_custkey, o_totalprice
    FROM orders
    WHERE o_totalprice > 1000
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice
    FROM orders o
    JOIN high_value_orders hvo ON o.o_custkey = hvo.o_custkey
    WHERE o.o_totalprice < hvo.o_totalprice
),
supplier_summary AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
),
winning_suppliers AS (
    SELECT s.s_suppkey, 
           s.s_name,
           ss.total_avail_qty,
           ss.avg_supply_cost,
           CASE 
               WHEN ss.part_count > 5 THEN 'High'
               ELSE 'Low'
           END AS supplier_category
    FROM supplier s
    JOIN supplier_summary ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_avail_qty > 100
)
SELECT
    n.n_name AS nation_name,
    SUM(COALESCE(o.o_totalprice, 0)) AS total_orders_value,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT ws.supplier_category, ', ') AS supplier_categories
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN winning_suppliers ws ON ws.s_suppkey = l.l_suppkey
WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY n.n_name
HAVING SUM(COALESCE(o.o_totalprice, 0)) > 50000
ORDER BY total_orders_value DESC;
