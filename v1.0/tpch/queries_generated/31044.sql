WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredSales AS (
    SELECT ts.o_orderkey, ts.total_price, ROW_NUMBER() OVER (ORDER BY ts.total_price DESC) AS rnk
    FROM TotalSales ts
    WHERE ts.total_price > 5000
),
RegionalSuppliers AS (
    SELECT n.n_name AS nation_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
CombinedResults AS (
    SELECT CONCAT('Order #', fs.o_orderkey, ' has a total price of ', CAST(fs.total_price AS VARCHAR(50))) AS order_summary,
           COALESCE(rs.nation_name, 'No Nation') AS supplier_region,
           sh.level
    FROM FilteredSales fs
    LEFT JOIN RegionalSuppliers rs ON fs.total_price > 10000
    LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = fs.o_orderkey
    WHERE sh.level IS NULL OR sh.s_acctbal > 5000
)
SELECT cr.order_summary, cr.supplier_region, cr.level
FROM CombinedResults cr
ORDER BY cr.level DESC, cr.order_summary;
