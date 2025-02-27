WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
OrderDetails AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
           GROUP_CONCAT(CONCAT('Part: ', p.p_name, ' | Quantity: ', l.l_quantity) ORDER BY l.l_linenumber) AS line_items
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice
),
Summary AS (
    SELECT c.c_nationkey, r.r_name AS region_name, COUNT(co.o_orderkey) AS total_orders,
           SUM(co.o_totalprice) AS total_revenue,
           STRING_AGG( DISTINCT co.c_name) AS unique_customers,
           MAX(co.o_orderdate) AS last_order_date
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY c.c_nationkey, r.r_name
)
SELECT s.region_name, s.total_orders, s.total_revenue,
       s.unique_customers, s.last_order_date,
       COUNT(DISTINCT p.p_partkey) AS total_parts_sold
FROM Summary s
JOIN lineitem l ON s.total_orders > 0
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY s.region_name, s.total_orders, s.total_revenue, s.unique_customers, s.last_order_date
ORDER BY s.total_revenue DESC;
