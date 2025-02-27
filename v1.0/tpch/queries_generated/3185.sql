WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_name,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS Rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
SupplierCosts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
LineitemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice,
           AVG(l.l_tax) AS AvgTax,
           COUNT(DISTINCT l.l_partkey) AS DistinctParts
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.o_orderkey,
       r.o_orderdate,
       r.c_name,
       ls.TotalPrice,
       ss.TotalSupplyCost,
       CASE 
           WHEN ls.TotalPrice IS NULL THEN 0 
           ELSE ls.TotalPrice - COALESCE(ss.TotalSupplyCost, 0) 
       END AS ProfitLoss,
       CASE 
           WHEN r.Rank = 1 THEN 'Latest Order'
           ELSE 'Previous Order'
       END AS OrderStatus
FROM RankedOrders r
LEFT JOIN LineitemSummary ls ON r.o_orderkey = ls.l_orderkey
FULL OUTER JOIN SupplierCosts ss ON ls.TotalPrice > 100000 AND ss.ps_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
)
WHERE r.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY r.o_orderdate DESC, ProfitLoss DESC;
