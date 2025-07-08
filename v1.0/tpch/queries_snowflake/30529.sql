WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
ProductInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS rank_within_type
    FROM part p
    WHERE p.p_size < 50 AND p.p_retailprice IS NOT NULL
),
AggregatedData AS (
    SELECT n.n_name, SUM(ps.ps_availqty) AS total_available,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_name
),
FinalReport AS (
    SELECT a.n_name, a.total_available, a.avg_price, 
           COALESCE(h.level, -1) AS supplier_level
    FROM AggregatedData a
    LEFT JOIN SupplierHierarchy h ON a.total_available > 100
    WHERE a.avg_price > 300
)
SELECT f.n_name, f.total_available, f.avg_price, 
       CASE 
           WHEN f.supplier_level = -1 THEN 'No Suppliers'
           ELSE CAST(f.supplier_level AS VARCHAR)
       END AS supplier_tier
FROM FinalReport f
WHERE f.total_available IS NOT NULL
ORDER BY f.avg_price DESC
LIMIT 10
