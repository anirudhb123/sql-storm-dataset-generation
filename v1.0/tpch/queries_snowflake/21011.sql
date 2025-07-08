
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
),
RegionSales AS (
    SELECT n.n_regionkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY n.n_regionkey
),
SupplierOrders AS (
    SELECT s.s_suppkey, COUNT(o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey
),
CombinedData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(so.order_count, 0) AS order_count,
        COALESCE(rs.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) > 100000 THEN 'High'
            WHEN COALESCE(rs.total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM supplier s
    LEFT JOIN SupplierOrders so ON s.s_suppkey = so.s_suppkey
    LEFT JOIN RegionSales rs ON s.s_nationkey = (
        SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE' LIMIT 1
    )
)
SELECT 
    ch.s_suppkey,
    ch.s_name,
    ch.order_count,
    ch.total_sales,
    ch.sales_category,
    ROW_NUMBER() OVER (PARTITION BY ch.sales_category ORDER BY ch.total_sales DESC) AS sales_rank
FROM CombinedData ch
WHERE ch.order_count > (SELECT AVG(so.order_count) FROM SupplierOrders so)
ORDER BY ch.sales_category, sales_rank;
