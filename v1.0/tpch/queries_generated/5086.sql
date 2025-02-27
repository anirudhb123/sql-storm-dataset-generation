WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_value,
        ss.part_count
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_supply_value > (
        SELECT AVG(total_supply_value) 
        FROM SupplierStats
    )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        co.total_spent
    FROM CustomerOrders co
    WHERE co.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrders
    )
)
SELECT 
    hvs.s_suppkey,
    hvs.s_name,
    tc.c_custkey,
    tc.c_name,
    tc.order_count,
    tc.total_spent
FROM HighValueSuppliers hvs
CROSS JOIN TopCustomers tc
ORDER BY hvs.total_supply_value DESC, tc.total_spent DESC;
