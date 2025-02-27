WITH RECURSIVE country_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    UNION ALL
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) + co.total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN country_orders co ON co.c_custkey = c.c_custkey
    WHERE co.total_spent < 10000
    GROUP BY c.c_custkey, c.c_name
),
supplier_options AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
revenue_rank AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
    GROUP BY l.l_orderkey
)

SELECT 
    co.c_name AS customer_name,
    so.s_name AS supplier_name,
    r.revenue AS order_revenue,
    CASE 
        WHEN r.rn = 1 THEN 'Highest Revenue'
        ELSE 'Other Revenue'
    END AS revenue_category
FROM country_orders co
LEFT JOIN supplier_options so ON co.c_custkey = so.s_suppkey
JOIN revenue_rank r ON co.c_custkey = r.l_orderkey
WHERE co.total_spent > (SELECT AVG(total_spent) FROM country_orders)
AND so.total_value IS NOT NULL
ORDER BY co.c_name, r.order_revenue DESC;

