WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS Level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT n.n_name, COUNT(DISTINCT sh.s_suppkey) AS QualifiedSuppliers,
       SUM(CASE WHEN ps.TotalCost IS NOT NULL THEN ps.TotalCost ELSE 0 END) AS TotalPartCost,
       AVG(CASE WHEN os.RevenueRank <= 5 THEN os.TotalRevenue ELSE NULL END) AS AvgTopRevenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartSupplier ps ON ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l 
                                               JOIN orders o ON l.l_orderkey = o.o_orderkey
                                               WHERE o.o_orderstatus = 'F')
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o 
                                               WHERE o.o_orderstatus = 'F')
GROUP BY n.n_name
HAVING AVG(sh.s_acctbal) > 5000
ORDER BY QualifiedSuppliers DESC, TotalPartCost DESC;
