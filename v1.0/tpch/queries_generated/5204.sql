WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
top_orders AS (
    SELECT ro.o_orderkey, ro.o_orderstatus, ro.total_revenue
    FROM ranked_orders ro
    WHERE ro.rank <= 5
),
customer_revenue AS (
    SELECT c.c_custkey, c.c_name, SUM(to.total_revenue) AS total_customer_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN top_orders to ON o.o_orderkey = to.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT c.c_name, c.total_customer_revenue, r.r_name
FROM customer_revenue c
JOIN nation n ON c.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
ORDER BY c.total_customer_revenue DESC;
