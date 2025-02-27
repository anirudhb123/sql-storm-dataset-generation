WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * li.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue
    FROM SupplierRevenue sr
    JOIN supplier s ON sr.s_suppkey = s.s_suppkey
    ORDER BY sr.total_revenue DESC
    LIMIT 10
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_spent
    FROM CustomerOrders co
    ORDER BY co.total_spent DESC
    LIMIT 5
)
SELECT ts.s_name AS supplier_name, hsc.c_name AS customer_name, hsc.total_spent, ts.total_revenue
FROM TopSuppliers ts
JOIN HighSpendingCustomers hsc ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_totalprice > 10000
)
ORDER BY ts.total_revenue DESC, hsc.total_spent DESC;
