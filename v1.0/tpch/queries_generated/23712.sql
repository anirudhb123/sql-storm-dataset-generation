WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
),
PartWithPriceRank AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS LineItemCount,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
           SUM(coalesce(o.o_totalprice, 0)) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_name, s.s_name, o.LineItemCount, o.TotalRevenue,
       CASE WHEN c.TotalOrders > 5 THEN 'Frequent' ELSE 'Infrequent' END AS CustomerType,
       COUNT(DISTINCT c.c_custkey) OVER (PARTITION BY p.p_partkey) AS CustomerCount
FROM PartWithPriceRank p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN OrderStats o ON o.LineItemCount > 10
JOIN CustomerOrder c ON c.TotalSpent > 1000
WHERE p.PriceRank < 5
  AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment IS NOT NULL)
  AND COALESCE(c.TotalOrders, 0) > 0
  AND NOT EXISTS (SELECT 1 FROM customer co WHERE co.c_custkey = c.c_custkey 
                  AND co.c_acctbal < 100)
ORDER BY o.TotalRevenue DESC, p.p_retailprice ASC
LIMIT 10;
