
WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           c.c_mktsegment, 
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
           COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           SUM(li.l_quantity) AS TotalQuantity
    FROM part p
    JOIN lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT r.r_name, 
       COUNT(DISTINCT s.s_suppkey) AS SupplierCount, 
       SUM(ss.TotalSupplyCost) AS TotalCost,
       AVG(pd.TotalQuantity) AS AvgPartQuantity,
       COUNT(DISTINCT ro.o_orderkey) AS RecentOrderCount
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
LEFT JOIN PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey) AND ro.OrderRank <= 10)
WHERE r.r_name LIKE 'N%'
GROUP BY r.r_name
ORDER BY TotalCost DESC;
