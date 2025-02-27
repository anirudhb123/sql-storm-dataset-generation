WITH RECURSIVE nation_sales AS (
    SELECT n.n_nationkey,
           n.n_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
),
filtered_sales AS (
    SELECT n.n_name,
           ns.total_sales
    FROM nation n
    LEFT JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
    WHERE ns.total_sales IS NOT NULL OR n.r_regionkey IN (SELECT DISTINCT r_regionkey FROM region)

),
top_sales AS (
    SELECT f.n_name,
           f.total_sales,
           ROW_NUMBER() OVER (ORDER BY f.total_sales DESC) AS sales_position
    FROM filtered_sales f
    WHERE f.total_sales > (SELECT AVG(total_sales) FROM filtered_sales)
)
SELECT t.n_name,
       COALESCE(t.total_sales, 0) AS sales_value,
       CASE 
           WHEN t.sales_position <= 5 THEN 'Top Seller'
           ELSE 'Regular Seller'
       END AS seller_category,
       CONCAT(t.n_name, ' has total sales of $', CAST(COALESCE(t.total_sales, 0) AS CHAR)) AS display_message
FROM top_sales t
FULL OUTER JOIN nation n ON n.n_nationkey = t.n_name
ORDER BY sales_value DESC NULLS LAST
LIMIT 10;
