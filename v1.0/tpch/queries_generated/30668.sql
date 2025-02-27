WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_orderdate, oh.order_level + 1
    FROM orders oh
    JOIN OrderHierarchy oh_parent ON oh.o_custkey = oh_parent.o_custkey
    WHERE oh.o_orderstatus = 'O' AND oh.o_orderdate > oh_parent.o_orderdate
),
HighValueSuppliers AS (
    SELECT ps.ps_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
RecentOrders AS (
    SELECT DISTINCT o.o_orderkey, c.c_nationkey, customers_order.level,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS ord_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN OrderHierarchy customers_order ON o.o_orderkey = customers_order.o_orderkey
)
SELECT r.r_name, SUM(roh.total_price) AS total_revenue,
       COUNT(DISTINCT ro.o_orderkey) AS order_count,
       COALESCE(MAX(roh.avg_discount), 0) AS max_discount
FROM RecentOrders ro
JOIN lineitem l ON l.l_orderkey = ro.o_orderkey
JOIN (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           AVG(l.l_discount) AS avg_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
) roh ON ro.o_orderkey = roh.o_orderkey
JOIN nation n ON ro.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN HighValueSuppliers vs ON vs.ps_suppkey = l.l_suppkey
WHERE ro.ord_rank <= 10
GROUP BY r.r_name
ORDER BY total_revenue DESC;
