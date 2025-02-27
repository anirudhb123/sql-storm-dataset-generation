WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, s.s_suppkey
),
TopSuppliers AS (
    SELECT n_name, s_suppkey, TotalCost,
           RANK() OVER (PARTITION BY n_name ORDER BY TotalCost DESC) AS Rank
    FROM NationSupplier
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_custkey
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(od.Revenue) AS TotalRevenue
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.custkey, c.c_name, TotalRevenue,
           RANK() OVER (ORDER BY TotalRevenue DESC) AS Rank
    FROM CustomerRevenue c
)
SELECT ts.n_name AS SupplierNation, 
       ts.s_suppkey AS SupplierKey, 
       ts.TotalCost AS SupplierTotalCost, 
       tc.c_name AS CustomerName, 
       tc.TotalRevenue AS CustomerTotalRevenue
FROM TopSuppliers ts
JOIN TopCustomers tc ON ts.Rank = 1
WHERE ts.Rank <= 10 AND tc.Rank <= 10
ORDER BY ts.SupplierNation, ts.TotalCost DESC, tc.TotalRevenue DESC;
