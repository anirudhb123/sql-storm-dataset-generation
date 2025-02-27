WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_name, sc.total_supply_cost
    FROM supplier s
    JOIN SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY sc.total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.s_name, co.c_name, o.order_date, o.total_order_value
FROM TopSuppliers ts
JOIN CustomerOrders co ON ts.total_supply_cost >= co.order_count * 100
JOIN OrderDetails o ON o.total_order_value > 5000
WHERE o.order_date > '2022-01-01'
ORDER BY ts.total_supply_cost DESC, co.total_spent DESC;
