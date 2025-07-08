
WITH RECURSIVE RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedSales AS (
    SELECT 
        n_nationkey,
        n_name,
        total_sales,
        sales_rank,
        MAX(total_sales) OVER () AS max_sales
    FROM 
        RegionalSales
)
SELECT 
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        WHEN rs.total_sales >= max_sales * 0.9 THEN 'Top Performer'
        ELSE 'Average Performer'
    END AS performance_category
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.n_nationkey LIMIT 1)
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    total_sales DESC;
