WITH recursive
  ranked_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
  ),
  customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN ranked_orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
  ),
  parts_with_discount AS (
    SELECT ps.ps_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_cost,
           CASE 
             WHEN AVG(ps.ps_supplycost) > 100 THEN 'High Cost'
             ELSE 'Low Cost'
           END AS cost_category
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, p.p_name
  ),
  high_value_customers AS (
    SELECT cs.*, r.r_name,
           CASE 
             WHEN cs.total_spent IS NULL THEN 0 
             ELSE cs.total_spent * 0.1
           END AS discount
    FROM customer_summary cs
    JOIN nation n ON cs.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE cs.total_spent >= 2000
  )

SELECT 
    hvc.c_custkey,
    hvc.c_name,
    p.p_name,
    p.total_available,
    p.average_cost,
    COALESCE(orders_ordered.total_orders, 0) AS total_orders,
    hvc.discount,
    CASE 
      WHEN hvc.last_order_date IS NOT NULL AND hvc.last_order_date < CURRENT_DATE - INTERVAL '30 days' THEN 'Inactive'
      ELSE 'Active'
    END AS customer_status
FROM high_value_customers hvc
LEFT JOIN (
    SELECT o.o_custkey, COUNT(l.l_orderkey) AS total_orders
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_custkey
) orders_ordered ON hvc.c_custkey = orders_ordered.o_custkey
INNER JOIN parts_with_discount p ON hvc.total_spent / 100 >= p.total_available
WHERE hvc.discount IS NOT NULL
ORDER BY hvc.c_custkey, hvc.total_spent DESC
FETCH FIRST 100 ROWS ONLY;
