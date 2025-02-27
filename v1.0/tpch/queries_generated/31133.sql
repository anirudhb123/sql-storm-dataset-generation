WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice > 100
),
PartSupplierAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT p.p_name, p.p_brand, psa.total_supplycost, os.total_revenue,
           COALESCE(sh.level, 0) AS supplier_level
    FROM FilteredParts p
    LEFT JOIN PartSupplierAggregates psa ON p.p_partkey = psa.ps_partkey
    LEFT JOIN OrderStatistics os ON os.total_revenue > 10000
    LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name LIKE '%United%'
    )
)
SELECT fr.p_name, fr.p_brand, fr.total_supplycost, fr.total_revenue, fr.supplier_level
FROM FinalReport fr
WHERE fr.total_supplycost IS NOT NULL
ORDER BY fr.supplier_level DESC, fr.total_revenue DESC;
