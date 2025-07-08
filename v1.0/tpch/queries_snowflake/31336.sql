WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    INNER JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_partkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size BETWEEN 1 AND 50
),
TopParts AS (
    SELECT fp.p_partkey, fp.p_name, fp.p_size, fp.p_retailprice
    FROM FilteredParts fp
    WHERE fp.rank <= 5
),
NationalSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(ts.total_sales) AS nation_sales
    FROM nation n
    JOIN TotalSales ts ON ts.l_partkey IN (SELECT p.p_partkey FROM part p JOIN supplier s ON p.p_partkey = s.s_suppkey WHERE s.s_acctbal IS NOT NULL)
    GROUP BY n.n_nationkey, n.n_name
),
SupplierAverage AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal
    FROM supplier
    GROUP BY s_nationkey
)
SELECT ns.n_name, ns.nation_sales, sa.avg_acctbal
FROM NationalSales ns
FULL OUTER JOIN SupplierAverage sa ON ns.n_nationkey = sa.s_nationkey
WHERE ns.nation_sales IS NOT NULL OR sa.avg_acctbal IS NOT NULL
ORDER BY ns.nation_sales DESC NULLS LAST;
