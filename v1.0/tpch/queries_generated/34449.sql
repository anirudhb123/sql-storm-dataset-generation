WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_comment NOT LIKE '%damaged%'
    GROUP BY ps.ps_partkey
),
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT p.p_partkey, p.p_name, p.p_retailprice, 
    COALESCE(ps.total_supplycost, 0) AS total_supplycost,
    ns.supplier_count,
    CASE 
        WHEN ns.avg_acctbal > 1000 THEN 'High'
        WHEN ns.avg_acctbal IS NULL THEN 'No Suppliers'
        ELSE 'Low'
    END AS acctbal_category,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY p.p_retailprice DESC) AS part_rank
FROM part p
LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN NationStats ns ON ns.supplier_count > 0
LEFT JOIN region r ON ns.n_nationkey = r.r_regionkey
WHERE p.p_size BETWEEN 1 AND 50
  AND (p.p_comment IS NULL OR p.p_comment LIKE '%quality%')
ORDER BY p.p_retailprice DESC, ns.supplier_count DESC;
