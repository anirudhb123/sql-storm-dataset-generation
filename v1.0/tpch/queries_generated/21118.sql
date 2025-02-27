WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

TotalSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY l.l_partkey
),

FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           COALESCE(t.total_sales, 0) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    LEFT JOIN TotalSales t ON p.p_partkey = t.l_partkey
    WHERE p.p_retailprice BETWEEN 10.50 AND 100.00
           AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
)

SELECT ph.s_name, ph.s_acctbal, f.p_name, f.total_sales
FROM SupplierHierarchy ph
JOIN FilteredParts f ON ph.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
WHERE ph.level > 1
ORDER BY ph.s_acctbal DESC, f.total_sales ASC
LIMIT 10

UNION ALL

SELECT 'Aggregate' AS supplier_name, SUM(s.s_acctbal), NULL, SUM(s.s_acctbal)
FROM supplier s
WHERE s.s_acctbal IS NOT NULL
HAVING SUM(s.s_acctbal) < 1000000
ORDER BY 2 DESC;
