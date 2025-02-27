WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), 
PartCount AS (
    SELECT ps_partkey, COUNT(DISTINCT ps_suppkey) AS supplier_count
    FROM partsupp
    GROUP BY ps_partkey
),
EnhancedPart AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           COALESCE(pc.supplier_count, 0) AS supplier_count,
           CASE 
               WHEN p.p_retailprice > 100 THEN 'Expensive'
               ELSE 'Affordable' 
           END AS price_category
    FROM part p
    LEFT JOIN PartCount pc ON p.p_partkey = pc.ps_partkey
),
RankedParts AS (
    SELECT ep.*, 
           RANK() OVER (PARTITION BY ep.price_category ORDER BY ep.p_retailprice DESC) AS price_rank
    FROM EnhancedPart ep
)
SELECT 
    ep.p_partkey, 
    ep.p_name, 
    ep.price_category, 
    ep.p_retailprice, 
    sh.s_name AS supplier_name,
    sh.level AS supplier_level,
    ep.supplier_count
FROM RankedParts ep
LEFT JOIN SupplierHierarchy sh ON ep.supplier_count > 0 AND ep.supplier_count <= 5
WHERE ep.price_rank <= 3
ORDER BY ep.price_category, ep.p_retailprice DESC, sh.level
LIMIT 50;
