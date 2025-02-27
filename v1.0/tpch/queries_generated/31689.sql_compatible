
WITH RECURSIVE NationalProductSales (n_name, total_sales, level) AS (
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 1 AS level
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
    UNION ALL
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, level + 1
    FROM NationalProductSales nps
    JOIN nation n ON nps.n_name = n.n_name
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE level < 5
    GROUP BY n.n_name, level
),
SalesRanked AS (
    SELECT n_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM NationalProductSales
)
SELECT sr.n_name, sr.total_sales, sr.sales_rank,
       CASE WHEN sr.sales_rank <= 10 THEN 'Top 10'
            WHEN sr.total_sales IS NULL THEN 'No Sales'
            ELSE 'Below Top 10' END AS ranking_category,
       COALESCE(px.promotional_comment, 'No Promotion') AS promotional_details
FROM SalesRanked sr
LEFT JOIN (
    SELECT p.p_name, p.p_comment AS promotional_comment
    FROM part p
    WHERE p.p_retailprice > 100 AND p.p_size < 20
) px ON sr.n_name LIKE '%' || COALESCE(NULLIF(px.p_name, ''), 'Generic') || '%'
WHERE sr.total_sales IS NOT NULL
ORDER BY sr.sales_rank;
