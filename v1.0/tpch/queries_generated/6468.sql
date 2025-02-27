WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 5
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), ProductSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ts.s_name AS Supplier_Name,
    co.c_name AS Customer_Name,
    ps.p_name AS Product_Name,
    ts.total_cost AS Supplier_Cost,
    co.order_count AS Customer_Orders,
    ps.total_sales AS Product_Sales
FROM TopSuppliers ts
JOIN CustomerOrders co ON co.order_count > 5
JOIN ProductSales ps ON ps.total_sales > 1000
ORDER BY ts.total_cost DESC, co.order_count DESC, ps.total_sales DESC;
