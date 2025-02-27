WITH RegionalSales AS (
    SELECT n.n_name AS nation_name,
           r.r_name AS region_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_orderdate BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    GROUP BY n.n_name, r.r_name
),
AverageSales AS (
    SELECT region_name,
           AVG(total_sales) AS avg_sales
    FROM RegionalSales
    GROUP BY region_name
)
SELECT rs.nation_name,
       rs.region_name,
       rs.total_sales,
       as.avg_sales
FROM RegionalSales rs
JOIN AverageSales as ON rs.region_name = as.region_name
WHERE rs.total_sales > as.avg_sales
ORDER BY rs.region_name, rs.total_sales DESC;
