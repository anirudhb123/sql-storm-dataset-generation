
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, sum(ps.ps_availqty) AS total_available_qty, 
           avg(ps.ps_supplycost) AS average_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAggregates AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_cost
    FROM lineitem l
    GROUP BY l.l_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sd.total_available_qty, sd.average_supply_cost,
           ROW_NUMBER() OVER (ORDER BY sd.total_available_qty DESC) AS rank
    FROM SupplierDetails sd
    JOIN supplier s ON sd.s_suppkey = s.s_suppkey
    WHERE sd.total_available_qty > 1000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_orders, co.total_spent,
           ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_spent > 5000
)
SELECT ts.s_name AS supplier_name, 
       tc.c_name AS customer_name, 
       tc.total_orders, 
       tc.total_spent,
       COALESCE(la.total_line_cost, 0) AS last_order_cost,
       CASE 
           WHEN ts.average_supply_cost IS NULL THEN 'NaN'
           ELSE CAST(ts.average_supply_cost AS VARCHAR)
       END AS average_supply_cost
FROM TopSuppliers ts
FULL OUTER JOIN TopCustomers tc ON ts.rank = tc.rank
LEFT JOIN LineItemAggregates la ON la.l_orderkey = (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = tc.c_custkey
    ORDER BY o.o_orderdate DESC
    LIMIT 1
)
WHERE ts.rank <= 10 OR tc.rank <= 10
ORDER BY COALESCE(ts.total_available_qty, 0) DESC, COALESCE(tc.total_spent, 0) DESC;
