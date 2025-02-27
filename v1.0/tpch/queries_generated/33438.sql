WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RegionSales AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
),
TopSales AS (
    SELECT r.r_name, r.total_sales,
           RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM RegionSales r
),
SuppliersWithSales AS (
    SELECT sh.s_suppkey, sh.s_name, sh.level, ts.total_sales
    FROM SupplierHierarchy sh
    LEFT JOIN TopSales ts ON ts.r_name = (
        SELECT r_name 
        FROM RegionSales 
        ORDER BY total_sales DESC 
        LIMIT 1
    )
)
SELECT s.s_custkey, s.c_name, COALESCE(sws.s_name, 'No Supplier') AS supplier_name,
       COALESCE(sws.total_sales, 0) AS supplier_total_sales
FROM customer s
LEFT JOIN SuppliersWithSales sws ON s.c_nationkey = sws.s_nationkey
WHERE s.c_acctbal > 1000
ORDER BY s.c_name, supplier_total_sales DESC;
