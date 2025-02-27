WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue
    FROM SupplierRevenue sr
    JOIN supplier s ON sr.s_suppkey = s.s_suppkey
    ORDER BY sr.total_revenue DESC
    LIMIT 10
),
CustomerOrderCount AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, coc.order_count
    FROM CustomerOrderCount coc
    ORDER BY coc.order_count DESC
    LIMIT 10
)
SELECT ts.s_name AS Supplier_Name, ts.total_revenue AS Supplier_Revenue, 
       tc.c_name AS Customer_Name, tc.order_count AS Customer_Order_Count
FROM TopSuppliers ts
CROSS JOIN TopCustomers tc
ORDER BY ts.total_revenue DESC, tc.order_count DESC;
