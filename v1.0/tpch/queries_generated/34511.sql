WITH RECURSIVE RegionalSales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY r.r_regionkey, r.r_name
), SalesRanking AS (
    SELECT r.r_regionkey, r.r_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionalSales r
)

SELECT s.r_regionkey, s.r_name, s.total_sales,
       CASE 
           WHEN s.total_sales IS NULL THEN 'No Sales'
           WHEN s.total_sales > 1000000 THEN 'High Sales'
           ELSE 'Regular Sales'
       END AS sales_category,
       COALESCE(n.n_comment, 'No nation comment') AS nation_comment
FROM SalesRanking s
LEFT JOIN nation n ON s.r_regionkey = n.n_regionkey
WHERE s.sales_rank <= 5
ORDER BY s.total_sales DESC;

SELECT 'Records from SalesRanking' AS info
UNION ALL
SELECT COUNT(*)::text
FROM SalesRanking;

SELECT COUNT(*)
FROM lineitem l
WHERE l.l_returnflag = 'R' 
    AND l.l_shipdate < (CURRENT_DATE - INTERVAL '30 days')
    AND l.l_discount BETWEEN 0.05 AND 0.1;
