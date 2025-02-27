WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
DenseRankedParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS PartRank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
AggregatedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS TotalCustomers, 
       (SELECT COUNT(*) FROM RankedSuppliers WHERE Rank = 1 AND s_nationkey = r.r_regionkey) AS TopSupplierCount,
       (SELECT SUM(TotalRevenue) FROM AggregatedOrders) AS OverallRevenue,
       GROUP_CONCAT(DISTINCT CONCAT(dp.p_name, ' (', dp.SupplierCount, ')') ORDER BY dp.PartRank) AS PopularParts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN DenseRankedParts dp ON c.c_nationkey = dp.PartRank
GROUP BY r.r_name
ORDER BY TotalCustomers DESC, r.r_name;
