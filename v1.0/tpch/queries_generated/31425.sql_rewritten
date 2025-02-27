WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal > 500
),
MaxTotalPrices AS (
    SELECT o.o_orderkey, MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_totalprice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierPartCounts AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RegionalSales AS (
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS region_name,
    COALESCE(supplier_part_counts.supplier_count, 0) AS total_suppliers,
    regional_sales.total_sales,
    CASE 
        WHEN regional_sales.total_sales IS NULL THEN 'No Sales' 
        WHEN regional_sales.total_sales > 1000000 THEN 'High Sales'
        WHEN regional_sales.total_sales BETWEEN 500000 AND 1000000 THEN 'Moderate Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM region r
LEFT JOIN SupplierPartCounts supplier_part_counts ON r.r_regionkey = supplier_part_counts.ps_partkey
LEFT JOIN RegionalSales regional_sales ON r.r_name = regional_sales.n_name
ORDER BY region_name, total_suppliers DESC, total_sales DESC