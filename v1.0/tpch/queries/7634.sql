
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
TopOrders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, c.c_name, c.c_acctbal
    FROM RankedOrders r
    JOIN customer c ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    WHERE r.OrderRank <= 10
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
)
SELECT TOP.o_orderdate AS OrderDate, TOP.c_name AS CustomerName, 
       TOP.o_totalprice AS TotalOrderPrice, SP.s_name AS Supplier,
       SP.TotalSupplyCost, 
       (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = TOP.o_orderkey) AS LineItemCount
FROM TopOrders TOP
JOIN SupplierParts SP ON SP.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = TOP.o_orderkey)
ORDER BY TOP.o_orderdate DESC, SP.TotalSupplyCost DESC;
