
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        n.n_name
), RankedSales AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.r_name AS region_name,
    rs.nation_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN rs.sales_rank <= 3 THEN 'Top 3 Nation'
        WHEN rs.sales_rank >= 4 AND rs.sales_rank <= 10 THEN '4 to 10 Nation'
        ELSE 'Lower Ranked Nation' 
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.nation_name)
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    r.r_name, total_sales DESC;
