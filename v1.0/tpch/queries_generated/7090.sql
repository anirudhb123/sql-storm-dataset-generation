WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalCost DESC
    LIMIT 10
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY TotalSpent DESC
    LIMIT 10
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS TotalSold, AVG(l.l_discount) AS AvgDiscount
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ts.s_name AS SupplierName,
    tc.c_name AS CustomerName,
    pd.p_name AS ProductName,
    pd.TotalSold,
    pd.AvgDiscount,
    ts.TotalCost AS SupplierTotalCost,
    tc.TotalSpent AS CustomerTotalSpent
FROM TopSuppliers ts
CROSS JOIN TopCustomers tc
JOIN ProductDetails pd ON pd.TotalSold > 100
WHERE ts.TotalCost > 100000
ORDER BY ts.TotalCost DESC, tc.TotalSpent DESC, pd.TotalSold DESC;
