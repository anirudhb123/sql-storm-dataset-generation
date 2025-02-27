WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerNationalities AS (
    SELECT c.c_custkey, n.n_name AS NationName
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT c.NationName, COUNT(DISTINCT o.o_orderkey) AS OrderCount,
       AVG(ho.OrderValue) AS AvgOrderValue, AVG(rs.TotalCost) AS AvgSupplierCost
FROM CustomerNationalities c
JOIN HighValueOrders ho ON c.c_custkey = ho.o_custkey
JOIN RankedSuppliers rs ON c.NationName = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = rs.s_nationkey)
WHERE rs.SupplierRank <= 3
GROUP BY c.NationName
ORDER BY OrderCount DESC;
