WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalCost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
HighVolumeParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS TotalSold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 1000
),
RegionalSales AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS TotalSales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)
SELECT 
    ts.s_name AS SupplierName,
    co.c_name AS CustomerName,
    hp.p_name AS PartName,
    rs.r_name AS RegionName,
    ts.TotalCost AS SupplierTotalCost,
    co.OrderCount AS CustomerOrderCount,
    co.TotalSpent AS CustomerTotalSpent,
    hp.TotalSold AS PartTotalSold,
    rs.TotalSales AS RegionTotalSales
FROM TopSuppliers ts
JOIN CustomerOrders co ON co.OrderCount > 5
JOIN HighVolumeParts hp ON TRUE
JOIN RegionalSales rs ON rs.TotalSales > 100000
ORDER BY ts.TotalCost DESC, co.TotalSpent DESC;
