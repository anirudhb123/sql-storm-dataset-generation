
WITH RECURSIVE recent_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderstatus
    FROM orders
    WHERE o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM orders o
    JOIN recent_orders ro ON o.o_orderkey < ro.o_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
ranked_suppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 100
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN recent_orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
high_spend_customers AS (
    SELECT cos.c_custkey, cos.c_name, cos.total_spent, cos.order_count
    FROM customer_order_summary cos
    JOIN ranked_suppliers rs ON cos.order_count > 5
    WHERE cos.total_spent > 10000
)
SELECT r.r_name, n.n_name, hsc.c_name, hsc.total_spent, hsc.order_count
FROM high_spend_customers hsc
JOIN customer c ON hsc.c_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN (
    SELECT ps.ps_partkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
) AS avg_prices ON hsc.total_spent > avg_prices.avg_price
ORDER BY r.r_name, hsc.total_spent DESC;
