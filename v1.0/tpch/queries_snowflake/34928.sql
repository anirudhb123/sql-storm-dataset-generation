WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartAnalysis AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS TypeRank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)
SELECT r.r_name,
       n.n_name,
       COUNT(DISTINCT c.c_custkey) AS CustomerCount,
       SUM(o.o_totalprice) AS TotalRevenue,
       COALESCE(SUM(pa.TotalCost), 0) AS TotalPartCost,
       AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) END) AS AvgDiscountedPrice
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN customer c ON s.s_suppkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN PartAnalysis pa ON pa.p_partkey = l.l_partkey
WHERE r.r_name IS NOT NULL
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY r.r_name, n.n_name
HAVING SUM(o.o_totalprice) > 1000000
ORDER BY TotalRevenue DESC, CustomerCount ASC;
