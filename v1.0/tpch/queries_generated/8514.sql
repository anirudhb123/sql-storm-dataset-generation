WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, TotalSupplyCost,
           ROW_NUMBER() OVER (ORDER BY TotalSupplyCost DESC) AS Rank
    FROM RankedSuppliers s
    WHERE TotalSupplyCost > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT cs.c_custkey, cs.c_name, COUNT(co.o_orderkey) AS TotalOrders,
       SUM(co.o_totalprice) AS TotalSpent, ts.s_name AS TopSupplier
FROM CustomerOrders co
JOIN TopSuppliers ts ON co.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_suppkey = ts.s_suppkey
)
JOIN customer cs ON co.c_custkey = cs.c_custkey
GROUP BY cs.c_custkey, cs.c_name, ts.s_name
ORDER BY TotalSpent DESC, TotalOrders DESC
LIMIT 10;
