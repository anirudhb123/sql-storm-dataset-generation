WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NULL OR s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND sh.level < 5
),
RegionalSales AS (
    SELECT n.n_regionkey, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey
),
PartSupplier AS (
    SELECT p.p_partkey, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty IS NOT NULL
),
FilteredParts AS (
    SELECT p.*, ps.ps_supplycost
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.p_partkey
    WHERE ps.rn = 1 AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_mfgr = p.p_mfgr
    )
),
ComplexAnalysis AS (
    SELECT r.r_name,
           COALESCE(r.total_sales, 0) AS total_sales,
           COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
           COUNT(DISTINCT fp.p_partkey) AS part_count
    FROM region r
    LEFT JOIN RegionalSales rs ON r.r_regionkey = rs.n_regionkey
    LEFT JOIN SupplierHierarchy sh ON r.r_name LIKE '%' || sh.s_name || '%'
    LEFT JOIN FilteredParts fp ON fp.p_size BETWEEN 5 AND 15
    GROUP BY r.r_name
)
SELECT r.r_name, r.total_sales, r.supplier_count, r.part_count,
       CASE 
           WHEN r.total_sales = 0 THEN 'No Sales'
           WHEN r.supplier_count < 5 THEN 'Few Suppliers'
           ELSE 'Healthy Market'
       END AS market_condition
FROM ComplexAnalysis r
WHERE r.part_count > 0
ORDER BY r.total_sales DESC, r.supplier_count ASC;
