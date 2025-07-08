WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent, COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT cus.c_custkey, cus.c_name, cus.TotalSpent, cus.OrderCount, r.r_name AS Region
    FROM CustomerOrderSummary cus
    JOIN nation n ON cus.c_custkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE cus.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerOrderSummary)
)
SELECT hs.c_name AS HighSpendingCustomer, hs.TotalSpent, rs.s_name AS SupplierName, rs.TotalCost
FROM HighSpendingCustomers hs
JOIN RankedSuppliers rs ON hs.Region = (SELECT r.r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = hs.c_custkey))
WHERE rs.Rank <= 3
ORDER BY hs.TotalSpent DESC, rs.TotalCost DESC;
