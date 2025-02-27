WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           1 AS tier
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           sh.tier + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
),

PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

NationSummary AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)

SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_retailprice,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    ns.total_acctbal,
    sh.tier,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY p.p_retailprice DESC) AS rank
FROM part p
LEFT JOIN PartSupplierCount ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN NationSummary ns ON p.p_brand = ns.n_name
LEFT JOIN SupplierHierarchy sh ON p.p_mfgr = sh.s_name
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
WHERE (p.p_retailprice IS NOT NULL AND p.p_retailprice > 50 AND p.p_size BETWEEN 5 AND 20)
   OR (sh.tier IS NOT NULL AND sh.tier <= 3)
ORDER BY ns.total_acctbal DESC, rank
LIMIT 100;
