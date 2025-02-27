WITH RECURSIVE nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    UNION ALL
    SELECT n.n_nationkey, n.n_name, total_sales * 1.1 AS total_sales
    FROM nation_sales ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
    WHERE total_sales < 10000
),
ranked_sales AS (
    SELECT n.n_name, ns.total_sales,
           RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM nation_sales ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
),
region_sales AS (
    SELECT r.r_name, SUM(rs.total_sales) AS region_total
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN ranked_sales rs ON n.n_nationkey = rs.n_nationkey
    GROUP BY r.r_name
)
SELECT r.r_name,
       COALESCE(region_total, 0) AS region_sales,
       CASE WHEN region_total IS NULL THEN 'No Sales' 
            ELSE CONCAT('Sales: $', FORMAT(region_total, 2)) 
       END AS sales_description
FROM region r
LEFT JOIN region_sales rs ON r.r_name = rs.r_name
WHERE region_total > 5000 OR region_total IS NULL
ORDER BY region_sales DESC;
