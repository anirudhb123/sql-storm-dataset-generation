
WITH RECURSIVE top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
order_line_totals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS line_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
avg_order_value AS (
    SELECT 
        AVG(line_total) AS average_value
    FROM order_line_totals
),
region_nation AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        n.n_nationkey, 
        n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rn.r_name,
    rn.n_name,
    COALESCE(SUM(lo.line_total), 0) AS total_line_sales,
    COALESCE(SUM(co.total_spent), 0) AS total_customer_spending,
    (SELECT AVG(total_orders) FROM customer_orders) AS avg_orders_per_customer,
    AVG(CASE WHEN s.total_cost IS NOT NULL THEN s.total_cost ELSE 0 END) AS avg_cost_of_top_suppliers
FROM region_nation rn
LEFT JOIN orders o ON rn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN order_line_totals lo ON o.o_orderkey = lo.o_orderkey
LEFT JOIN top_suppliers s ON true
LEFT JOIN customer_orders co ON o.o_custkey = co.c_custkey
GROUP BY rn.r_name, rn.n_name
ORDER BY total_line_sales DESC
LIMIT 5;
