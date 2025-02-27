WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
),
SupplierStatistics AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
           AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS TotalSpent,
           COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey
)
SELECT r.r_name, p.p_name, s.SupplierCount, s.AvgSupplyCost,
       c.TotalSpent, c.OrderCount,
       COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS ReturnedOrders,
       SUM(COALESCE(l.l_discount, 0)) AS TotalDiscounts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN CustomerOrderSummary c ON p.p_partkey = c.c_custkey
WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
  AND p.p_retailprice BETWEEN 10.00 AND 500.00
GROUP BY r.r_name, p.p_name, s.SupplierCount, s.AvgSupplyCost, c.TotalSpent, c.OrderCount
HAVING AVG(l.l_tax) IS NOT NULL 
   AND COUNT(l.l_orderkey) > 5
ORDER BY r.r_name, c.TotalSpent DESC
LIMIT 50;
