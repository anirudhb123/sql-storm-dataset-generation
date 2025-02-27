WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
HighValueCustomers AS (
    SELECT c.custkey, c.c_name, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
), 
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name,
           DENSE_RANK() OVER (ORDER BY sp.supplier_value DESC) AS rank
    FROM SupplierParts sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
)

SELECT 
    h.c_name AS Customer_Name,
    h.total_spent AS Total_Spent,
    COALESCE(t.rank, 0) AS Supplier_Rank,
    t.s_name AS Top_Supplier_Name,
    t.supplier_value AS Supplier_Value
FROM HighValueCustomers h
LEFT JOIN TopSuppliers t ON h.rank = t.rank
WHERE h.order_count > 1
ORDER BY h.total_spent DESC, t.supplier_value DESC;
