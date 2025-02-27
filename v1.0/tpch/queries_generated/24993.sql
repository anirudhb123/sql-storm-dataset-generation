WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.depth < 5
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, DENSE_RANK() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0 AND ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2))
), SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey
), CombinedResults AS (
    SELECT sh.s_name AS supplier_name, rp.p_name AS part_name, 
           COALESCE(ss.total_sales, 0) AS total_sales,
           rp.price_rank
    FROM RankedParts rp
    JOIN SupplierHierarchy sh ON EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_suppkey = sh.s_suppkey AND s.s_nationkey = sh.s_nationkey
    )
    LEFT JOIN SupplierSales ss ON sh.s_suppkey = ss.s_suppkey
)
SELECT DISTINCT
    cr.supplier_name,
    cr.part_name,
    cr.total_sales,
    CASE 
        WHEN cr.total_sales > 10000 THEN 'High-value Supplier'
        WHEN cr.total_sales BETWEEN 5000 AND 10000 THEN 'Medium-value Supplier'
        ELSE 'Low-value Supplier'
    END AS supplier_value_segment
FROM CombinedResults cr
WHERE cr.price_rank = 1 
  AND (cr.total_sales IS NOT NULL OR cr.total_sales < 1000)
ORDER BY cr.total_sales DESC, cr.supplier_name;
