WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_supply_cost
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY ss.total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > (SELECT AVG(total_spent) FROM (
          SELECT SUM(o.o_totalprice) AS total_spent
          FROM orders o
          WHERE o.o_orderstatus = 'F'
          GROUP BY o.o_custkey
    ) AS avg_total_spent)
)
SELECT ts.s_name, co.c_name, co.order_count, co.total_spent
FROM TopSuppliers ts
JOIN CustomerOrders co ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                          WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey) 
                                          GROUP BY ps.ps_suppkey 
                                          ORDER BY SUM(l.l_quantity * ps.ps_supplycost) DESC LIMIT 1)
ORDER BY co.total_spent DESC;
