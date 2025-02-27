WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
QualifiedCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > (SELECT AVG(total_spent) FROM 
                          (SELECT SUM(o_totalprice) AS total_spent 
                           FROM orders 
                           GROUP BY o_custkey) AS avg_spent)
),
MonthlyOrders AS (
    SELECT EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
           EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
           COUNT(o.o_orderkey) AS orders_count,
           SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    GROUP BY EXTRACT(YEAR FROM o.o_orderdate), 
             EXTRACT(MONTH FROM o.o_orderdate)
)
SELECT r.region_name, 
       MAX(m.orders_count) AS max_monthly_orders,
       COALESCE(SUM(cs.total_spent), 0) AS total_customer_spending,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
FROM region r 
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN QualifiedCustomers cs ON cs.c_custkey = (SELECT c.c_custkey 
                                                        FROM customer c 
                                                        WHERE c.c_nationkey = n.n_nationkey 
                                                        ORDER BY c.c_acctbal DESC 
                                                        LIMIT 1)
LEFT JOIN MonthlyOrders m ON m.order_month = EXTRACT(MONTH FROM CURRENT_DATE) 
                            AND m.order_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE s.s_acctbal IS NOT NULL
AND r.r_name LIKE '%East%'
AND ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
GROUP BY r.region_name
ORDER BY r.region_name
WITH ROLLUP;
