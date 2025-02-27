
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    AND sh.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(i.l_extendedprice * (1 - i.l_discount)) AS total_sales,
        COUNT(DISTINCT i.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem i ON o.o_orderkey = i.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(os.total_sales) AS region_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN OrderSummary os ON s.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_size >= 10))
    GROUP BY r.r_name
)
SELECT 
    rh.r_name,
    COALESCE(rs.region_sales, 0) AS total_sales,
    (SELECT AVG(region_sales) FROM RegionSales) AS avg_region_sales
FROM region rh
LEFT JOIN RegionSales rs ON rh.r_name = rs.r_name
ORDER BY total_sales DESC,
         rh.r_name;
