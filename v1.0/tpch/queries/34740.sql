WITH RECURSIVE RegionSales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY r.r_regionkey, r.r_name
    UNION ALL
    SELECT r.r_regionkey, r.r_name, total_sales * 1.1 AS total_sales
    FROM region r
    JOIN RegionSales rs ON r.r_regionkey = rs.r_regionkey
    WHERE rs.total_sales < 1000000
)
SELECT r.r_name,
       COALESCE(SUM(rs.total_sales), 0) AS total_region_sales,
       COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
       ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(rs.total_sales), 0) DESC) AS rank
FROM region r
LEFT JOIN RegionSales rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_region_sales DESC
LIMIT 10;