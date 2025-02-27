WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RegionSupplierSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(os.total_sales) AS total_region_sales,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN OrderStatistics os ON s.s_suppkey = os.o_orderkey
    WHERE r.r_name IS NOT NULL
    GROUP BY r.r_name
)
SELECT 
    rh.s_name,
    rh.hierarchy_level,
    COALESCE(rss.total_region_sales, 0) AS total_sales_region,
    rh.s_acctbal
FROM SupplierHierarchy rh
LEFT JOIN RegionSupplierSales rss ON rh.s_nationkey = rss.supplier_count
WHERE rh.hierarchy_level > 0
ORDER BY total_sales_region DESC, rh.s_acctbal DESC;
