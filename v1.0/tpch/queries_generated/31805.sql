WITH RECURSIVE DateRanges AS (
    SELECT MIN(o_orderdate) AS start_date, MAX(o_orderdate) AS end_date
    FROM orders
    UNION ALL
    SELECT DATE_ADD(start_date, INTERVAL 1 DAY), end_date
    FROM DateRanges
    WHERE start_date < end_date
),
SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
           COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
AveragePrice AS (
    SELECT p.p_partkey,
           AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OutstandingOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice - COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS outstanding_amount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT r.r_name,
       COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
       s.total_supplycost,
       p.avg_price,
       o.order_count,
       COUNT(DISTINCT d.start_date) AS active_days,
       AVG(o.outstanding_amount) AS avg_outstanding_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_stats s ON n.n_nationkey = s.s_nationkey
LEFT JOIN averageprice p ON s.parts_supplied > 10
LEFT JOIN customer_order_counts c ON s.s_suppkey = c.c_custkey
LEFT JOIN outstandingorders o ON c.order_count > 0
JOIN date_ranges d ON d.start_date < o.o_orderdate 
GROUP BY r.r_name, c.c_name, s.total_supplycost, p.avg_price, o.order_count
HAVING s.total_supplycost > 10000 AND active_days >= 30
ORDER BY total_supplycost DESC, customer_name ASC;
