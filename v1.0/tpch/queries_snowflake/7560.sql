WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionalSales AS (
    SELECT n.n_regionkey, SUM(ss.total_sales) AS regional_sales
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey
),
TopRegions AS (
    SELECT r.r_name, rs.regional_sales
    FROM region r
    JOIN RegionalSales rs ON r.r_regionkey = rs.n_regionkey
    ORDER BY rs.regional_sales DESC
    LIMIT 5
)
SELECT tr.r_name, tr.regional_sales, COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM TopRegions tr
JOIN supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE r.r_name = tr.r_name)
GROUP BY tr.r_name, tr.regional_sales
ORDER BY tr.regional_sales DESC;
