WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierPart AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
LineItemAggregate AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalReport AS (
    SELECT r.r_name, SUM(l.TotalRevenue) AS TotalRevenue, SUM(sp.TotalSupplyCost) AS TotalSupplyCost
    FROM RankedOrders ro
    JOIN LineItemAggregate l ON ro.o_orderkey = l.l_orderkey
    JOIN customer c ON ro.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN SupplierPart sp ON sp.ps_partkey IN (
        SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey
    )
    GROUP BY r.r_name
)
SELECT r_name, TotalRevenue, TotalSupplyCost, 
       (TotalRevenue - TotalSupplyCost) AS Profit
FROM FinalReport
ORDER BY Profit DESC;
