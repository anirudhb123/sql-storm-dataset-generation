WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
),
supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_tax) AS avg_tax, MIN(l.l_shipdate) AS first_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
),
ranked_orders AS (
    SELECT co.*, ls.total_sales, ls.avg_tax, ls.first_ship_date,
           RANK() OVER (PARTITION BY co.c_custkey ORDER BY ls.total_sales DESC) AS sales_rank
    FROM customer_orders co
    LEFT JOIN lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
)
SELECT nh.n_name, COUNT(DISTINCT ro.o_orderkey) AS total_orders,
       SUM(ro.total_sales) AS total_revenue, AVG(ro.avg_tax) AS avg_tax_rate,
       MAX(ro.first_ship_date) AS latest_shipping_date
FROM ranked_orders ro
JOIN customer c ON ro.c_custkey = c.c_custkey
JOIN nation_hierarchy nh ON c.c_nationkey = nh.n_nationkey
GROUP BY nh.n_name
HAVING COUNT(DISTINCT ro.o_orderkey) > 0
ORDER BY total_revenue DESC
LIMIT 10;
