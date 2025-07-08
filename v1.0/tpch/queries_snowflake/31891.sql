
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal <= 10000
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           MAX(l.l_shipdate) AS last_ship_date 
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey
),
SalesByRegion AS (
    SELECT n.n_name AS nation, r.r_name AS region, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 'Top Suppliers by Account Balance' AS report_title,
       sh.s_name,
       sh.s_suppkey,
       sb.region,
       sb.total_sales,
       ob.total_revenue,
       ob.customer_count,
       ob.last_ship_date
FROM SupplierHierarchy sh
LEFT JOIN SalesByRegion sb ON sh.s_nationkey = (
    SELECT n.n_nationkey FROM nation n WHERE n.n_name = sb.nation
    LIMIT 1
)
JOIN OrderStats ob ON sh.s_suppkey = (
    SELECT l.l_suppkey FROM lineitem l 
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderkey IN (
        SELECT o_orderkey FROM OrderStats
    )
    LIMIT 1
)
WHERE sh.level < 3
ORDER BY sb.total_sales DESC, ob.total_revenue DESC;
