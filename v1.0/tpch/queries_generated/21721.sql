WITH RECURSIVE RegionalSales AS (
    SELECT n.n_nationkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY n.n_nationkey, r.r_name
    
    UNION ALL

    SELECT n.n_nationkey, r.r_name, SUM(total_sales * 0.95) AS total_sales
    FROM RegionalSales rs
    JOIN nation n ON rs.n_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_name
),
BestSellingParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING part_sales > (SELECT AVG(part_sales) FROM (
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_sales
        FROM part p
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        GROUP BY p.p_partkey
    ) AS avg_sales)
),
StatusCount AS (
    SELECT o.o_orderstatus, COUNT(*) AS order_count
    FROM orders o
    GROUP BY o.o_orderstatus
)
SELECT r.r_name, 
       SUM(rs.total_sales) AS total_region_sales,
       b.p_name AS best_selling_part,
       sc.o_orderstatus,
       sc.order_count
FROM RegionalSales rs
JOIN region r ON r.r_name = rs.r_name
LEFT JOIN BestSellingParts b ON b.part_sales = (
    SELECT MAX(bp.part_sales) FROM BestSellingParts bp
    WHERE bp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty IS NOT NULL)
)
LEFT JOIN StatusCount sc ON sc.o_orderstatus = CASE 
    WHEN rs.total_sales IS NULL THEN 'O' 
    ELSE 'N' 
END
GROUP BY r.r_name, b.p_name, sc.o_orderstatus
HAVING COUNT(DISTINCT b.p_partkey) > 2
ORDER BY total_region_sales DESC, best_selling_part;
