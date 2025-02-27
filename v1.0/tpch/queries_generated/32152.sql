WITH RECURSIVE sales_hierarchy AS (
    SELECT s_nationkey, SUM(o_totalprice) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s_nationkey
),
nation_sales AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(sh.total_sales, 0) AS total_sales
    FROM nation n
    LEFT JOIN sales_hierarchy sh ON n.n_nationkey = sh.s_nationkey
),
region_sales AS (
    SELECT r.r_regionkey, r.r_name, SUM(ns.total_sales) AS region_sales
    FROM region r
    JOIN nation_sales ns ON ns.n_nationkey = (
        SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey
    )
    GROUP BY r.r_regionkey, r.r_name
),
ranked_sales AS (
    SELECT r_name, region_sales, 
           RANK() OVER (ORDER BY region_sales DESC) AS sales_rank
    FROM region_sales
)

SELECT r_name, region_sales, sales_rank
FROM ranked_sales
WHERE sales_rank <= 5
ORDER BY region_sales DESC
UNION ALL
SELECT 'Total Sales Across All Regions' AS r_name,
       SUM(region_sales) AS region_sales,
       NULL AS sales_rank
FROM region_sales
WHERE region_sales IS NOT NULL;
