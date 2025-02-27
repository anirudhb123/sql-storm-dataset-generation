WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O')
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS AggregateOrderValue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders, SUM(li.l_extendedprice) AS TotalRevenue,
       AVG(co.AggregateOrderValue) AS AvgOrderValue, ts.TotalSupplyCost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem li ON ps.ps_partkey = li.l_partkey
JOIN RankedOrders o ON li.l_orderkey = o.o_orderkey
JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN CustomerOrderSummary co ON o.o_custkey = co.c_custkey
WHERE o.OrderRank <= 10
GROUP BY r.r_name, ts.TotalSupplyCost
ORDER BY TotalRevenue DESC, r.r_name ASC;
