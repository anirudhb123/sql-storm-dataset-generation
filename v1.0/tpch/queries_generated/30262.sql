WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT DISTINCT ps_suppkey FROM partsupp)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.s_nationkey
),
AggregatedSales AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, n.n_name
),
RankedSales AS (
    SELECT 
        cust.nation_name,
        cust.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cust.nation_name ORDER BY cust.total_sales DESC) AS sales_rank
    FROM AggregatedSales cust
)
SELECT 
    sr.nation_name,
    sr.total_sales,
    sh.s_name,
    sh.s_address,
    CASE WHEN sr.sales_rank <= 5 THEN 'Top Sales' ELSE 'Other' END AS sales_category
FROM RankedSales sr
LEFT JOIN SupplierHierarchy sh ON sh.level = 0
WHERE sr.total_sales IS NOT NULL
AND (sr.nation_name LIKE 'A%' OR sr.nation_name LIKE 'B%')
ORDER BY sr.nation_name, sr.total_sales DESC;
