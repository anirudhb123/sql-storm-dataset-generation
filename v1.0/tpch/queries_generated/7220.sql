WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice > 300000
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN HighValueOrders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), SupplierDetails AS (
    SELECT ts.s_suppkey, ts.s_name, co.c_custkey, co.order_count, co.total_spent
    FROM TopSuppliers ts
    JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN HighValueOrders ho ON li.l_orderkey = ho.o_orderkey
    JOIN customer co ON ho.o_custkey = co.c_custkey
    GROUP BY ts.s_suppkey, ts.s_name, co.c_custkey, co.order_count, co.total_spent
), Summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(cd.total_spent) AS total_orders_spent
    FROM SupplierDetails cd
    JOIN TopSuppliers s ON cd.s_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_orders_spent DESC
)
SELECT s.s_name, s.total_orders_spent
FROM Summary s
WHERE s.total_orders_spent > 50000;
