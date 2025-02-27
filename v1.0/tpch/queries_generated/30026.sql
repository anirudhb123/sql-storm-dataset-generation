WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal BETWEEN sh.s_acctbal * 0.5 AND sh.s_acctbal * 1.5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RankedSales AS (
    SELECT ts.total_sales, ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalSales ts
),
QualifiedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s1.s_acctbal)
        FROM supplier s1
    )
    AND EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_suppkey = s.s_suppkey
        AND ps.ps_availqty > 100
    )
)
SELECT
    sh.s_name AS supplier_name,
    n.r_name AS region_name,
    ts.total_sales,
    rs.sales_rank
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN TotalSales ts ON sh.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_size BETWEEN 10 AND 20
        AND p.p_retailprice IS NOT NULL
        ORDER BY p.p_retailprice
        LIMIT 1
    )
)
JOIN RankedSales rs ON ts.total_sales > rs.total_sales * 0.9
ORDER BY sh.hierarchy_level, total_sales DESC;
