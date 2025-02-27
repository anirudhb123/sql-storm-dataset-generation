WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON s.s_nationkey = c.c_nationkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
TopCustomers AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
    FROM RankedOrders o
    WHERE o.rn <= 5
),
Summary AS (
    SELECT c.c_name AS customer_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders, AVG(o.o_totalprice) AS avg_order_value
    FROM TopCustomers o
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY c.c_name
)
SELECT s.s_name AS supplier_name, COUNT(DISTINCT sc.customer_name) AS unique_customers,
       SUM(sc.total_spent) AS supplier_revenue, AVG(sc.avg_order_value) AS avg_order_value_per_customer
FROM Summary sc
JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Supplier Nation Name')
GROUP BY s.s_name
ORDER BY supplier_revenue DESC
LIMIT 10;
