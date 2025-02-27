WITH RegionalSales AS (
    SELECT n.n_name AS nation_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
RankedSales AS (
    SELECT nation_name,
           total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionalSales
)
SELECT r.r_name AS region_name,
       COALESCE(rs.nation_name, 'No Sales') AS nation_name,
       COALESCE(rs.total_sales, 0.00) AS total_sales
FROM region r
LEFT JOIN RankedSales rs ON r.r_name = CASE
    WHEN rs.nation_name IS NOT NULL THEN (SELECT r_name FROM nation n INNER JOIN region r ON n.n_regionkey = r.r_regionkey WHERE n.n_name = rs.nation_name)
    ELSE NULL
END
ORDER BY r.r_regionkey, sales_rank
LIMIT 10;
