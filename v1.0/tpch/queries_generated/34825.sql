WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 
          (SELECT AVG(c2.c_acctbal) 
           FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
OrderStats AS (
    SELECT o.o_custkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, 
           c.c_name,
           coalesce(o.order_count, 0) AS total_orders,
           coalesce(o.total_spent, 0) AS total_value,
           RANK() OVER (ORDER BY coalesce(o.total_spent, 0) DESC) AS revenue_rank
    FROM customer c
    LEFT JOIN OrderStats o ON c.c_custkey = o.o_custkey
)
SELECT n.n_name AS nation_name,
       SUM(tc.total_value) AS nation_revenue,
       COUNT(DISTINCT tc.c_custkey) AS customer_count,
       MAX(tc.total_orders) AS max_orders,
       MIN(tc.total_orders) AS min_orders,
       AVG(tc.total_value) AS avg_order_value
FROM TopCustomers tc
JOIN nation n ON tc.c_nationkey = n.n_nationkey
WHERE tc.revenue_rank <= 10
GROUP BY n.n_name
ORDER BY nation_revenue DESC;
