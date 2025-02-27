WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_custkey
)
SELECT nd.n_name AS NationName, COUNT(DISTINCT os.o_custkey) AS TotalCustomers,
       SUM(rs.TotalSupplyCost) AS TotalSupplierCost, SUM(os.TotalRevenue) AS TotalRevenue
FROM NationDetails nd
JOIN RankedSupplier rs ON nd.n_nationkey = rs.s_nationkey
JOIN OrderSummary os ON os.o_custkey IN (
    SELECT DISTINCT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = nd.n_nationkey
)
GROUP BY nd.n_name
ORDER BY TotalRevenue DESC, TotalSupplierCost DESC;