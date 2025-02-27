WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity_sold, COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
)
SELECT co.c_name, ps.p_name, ts.s_name, ps.total_quantity_sold, co.total_spent
FROM CustomerOrders co
JOIN PartStatistics ps ON ps.total_quantity_sold > 100
JOIN TopSuppliers ts ON ts.total_supply_cost > 50000
WHERE co.total_spent > 10000
ORDER BY co.total_spent DESC, ps.total_quantity_sold DESC;
