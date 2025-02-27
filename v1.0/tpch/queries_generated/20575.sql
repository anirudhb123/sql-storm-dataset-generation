WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 as Level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, h.Level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy h ON s.s_nationkey = h.s_nationkey 
    WHERE s.s_acctbal IS NOT NULL AND s.acctbal < h.s_acctbal 
),

HighValueOrders AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate > '2023-01-01'
    GROUP BY o.o_orderkey
    HAVING TotalValue > (
        SELECT AVG(l2.l_extendedprice)
        FROM lineitem l2
        WHERE l2.l_discount < 0.05
    )
),

SupplierPerformance AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
           COUNT(DISTINCT ps.ps_partkey) AS DistinctPartsSupplied,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT DISTINCT
    r.r_name AS RegionName,
    n.n_name AS NationName,
    s.s_name AS SupplierName,
    sh.Level AS SupplierLevel,
    hp.o_orderkey AS HighValueOrder,
    sp.TotalSupplyCost,
    sp.DistinctPartsSupplied,
    CASE 
        WHEN sp.Rank = 1 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS SupplierStatus
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN HighValueOrders hp ON hp.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_acctbal < 1000
    )
)
JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
WHERE s.s_acctbal IS NOT NULL 
AND s.s_acctbal < (
    SELECT MIN(s2.s_acctbal)
    FROM supplier s2
    WHERE s2.s_comment LIKE '%loyal%'
) OR sp.TotalSupplyCost IS NULL
ORDER BY r.r_name, n.n_name, s.s_name;
