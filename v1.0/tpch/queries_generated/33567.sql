WITH RECURSIVE region_rank AS (
    SELECT r.r_regionkey, r.r_name, ROW_NUMBER() OVER (ORDER BY COUNT(n.n_nationkey) DESC) AS rank
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, ss.s_name, cos.c_name,
       cos.total_orders, cos.total_spent,
       ss.total_supply_cost,
       CASE WHEN cos.total_spent IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
FROM region_rank r
LEFT JOIN supplier_summary ss ON r.rank <= 5
LEFT JOIN customer_order_summary cos ON cos.total_orders > 10
WHERE r.r_regionkey IS NOT NULL
ORDER BY r.r_name, ss.total_supply_cost DESC;
