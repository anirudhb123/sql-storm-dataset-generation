WITH RegionSales AS (
    SELECT n.n_name AS nation_name,
           r.r_name AS region_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY n.n_name, r.r_name
),
TopRegions AS (
    SELECT region_name, 
           SUM(total_sales) AS total_region_sales
    FROM RegionSales
    GROUP BY region_name
    ORDER BY total_region_sales DESC
    LIMIT 5
)
SELECT r.region_name, 
       COALESCE(rs.total_region_sales, 0) AS total_sales, 
       CASE 
           WHEN COALESCE(rs.total_region_sales, 0) = 0 THEN 'No Sales' 
           ELSE 'Sales Present' 
       END AS sales_status,
       RANK() OVER (ORDER BY COALESCE(rs.total_region_sales, 0) DESC) AS sales_rank
FROM TopRegions r
LEFT JOIN RegionSales rs ON r.region_name = rs.region_name
ORDER BY sales_rank;
