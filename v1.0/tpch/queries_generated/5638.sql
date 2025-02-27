WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.OrderRank <= 10
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * li.l_quantity) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN TopOrders to ON li.l_orderkey = to.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
PerformanceRanking AS (
    SELECT sp.s_suppkey, sp.s_name, sp.TotalSupplyCost,
           RANK() OVER (ORDER BY sp.TotalSupplyCost DESC) AS PerformanceRank
    FROM SupplierPerformance sp
)

SELECT pr.PerformanceRank, pr.s_name, pr.TotalSupplyCost
FROM PerformanceRanking pr
WHERE pr.PerformanceRank <= 5
ORDER BY pr.TotalSupplyCost DESC;
