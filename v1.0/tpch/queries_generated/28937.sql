WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_orders, co.total_spent
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_orders > (SELECT AVG(total_orders) FROM CustomerOrders)
    ORDER BY co.total_spent DESC
    LIMIT 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT tc.c_name AS Customer_Name, 
       sd.s_name AS Supplier_Name, 
       sd.p_name AS Part_Name, 
       sd.ps_supplycost AS Supply_Cost, 
       tc.total_orders AS Total_Orders, 
       tc.total_spent AS Total_Spent
FROM TopCustomers tc
JOIN SupplierDetails sd ON tc.c_custkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name LIKE '%Supplier%')
ORDER BY tc.total_spent DESC, sd.ps_supplycost ASC;
