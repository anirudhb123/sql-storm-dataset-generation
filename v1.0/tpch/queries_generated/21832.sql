WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.Level < 3
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) AS TotalSupplyCost
    FROM partsupp ps
    WHERE ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) >= 1
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Price Unavailable' 
               ELSE CONCAT('Retail Price: $', CAST(p.p_retailprice AS VARCHAR))
           END AS PriceDetails
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 100
)
SELECT DISTINCT 
    n.n_name AS Nation,
    c.c_name AS Customer,
    ph.s_name AS SupplierName,
    pd.PriceDetails,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'F') AS FinalizedOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN PartSupplier ps ON ps.ps_partkey = l.l_partkey
JOIN ProductDetails pd ON pd.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
JOIN supplier ph ON sh.s_suppkey = ph.s_suppkey
WHERE l.l_returnflag = 'R' AND l.l_linestatus = 'O'
GROUP BY n.n_name, c.c_name, ph.s_name, pd.PriceDetails
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY RevenueRank, Nation;
