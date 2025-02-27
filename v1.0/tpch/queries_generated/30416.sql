WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_name ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
),
supplier_info AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT r.r_name,
       COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       SUM(ls.total_revenue) AS total_revenue,
       AVG(oh.o_totalprice) AS average_order_value,
       MAX(oh.o_orderdate) AS last_order_date
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_info s ON n.n_nationkey = s.s_nationkey
LEFT JOIN lineitem_summary ls ON ls.l_orderkey IN (
    SELECT o.o_orderkey
    FROM order_hierarchy oh
    WHERE oh.order_rank <= 5
)
LEFT JOIN orders oh ON oh.o_orderkey = ls.l_orderkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, s.s_name
HAVING SUM(ls.total_revenue) > 5000
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
