WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RankedOrders AS (
    SELECT o_o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
SupplierParts AS (
    SELECT ps.partkey, ps.suppkey, SUM(ps.ps_availqty) AS AvailableStock
    FROM partsupp ps
    GROUP BY ps.partkey, ps.suppkey
)
SELECT p.p_partkey, 
       p.p_name, 
       p.p_retailprice, 
       COALESCE(sp.AvailableStock, 0) AS AvailableStock,
       COALESCE(oh.TotalRevenue, 0) AS CustomerRevenue,
       sh.level AS SupplierLevel,
       r.r_name AS RegionName
FROM part p
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.partkey
LEFT JOIN RankedOrders oh ON oh.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = p.p_partkey % 5) 
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = sp.suppkey)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = sp.suppkey
WHERE p.p_size BETWEEN 10 AND 20
  AND sh.level IS NULL
ORDER BY p.p_retailprice DESC
FETCH FIRST 100 ROWS ONLY;
