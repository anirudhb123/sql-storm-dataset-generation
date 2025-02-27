WITH RECURSIVE regional_sales AS (
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        n.n_name
    
    UNION ALL

    SELECT 
        'All Regions' AS nation_name,
        SUM(total_sales) AS total_sales
    FROM 
        regional_sales
),
sales_ranked AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sale_rank
    FROM 
        regional_sales
)
SELECT 
    r.r_name AS region_name,
    COALESCE(sr.nation_name, 'No Sales') AS nation_name,
    COALESCE(sr.total_sales, 0) AS total_sales,
    CASE 
        WHEN sr.sale_rank <= 3 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    sales_ranked sr ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = sr.nation_name)
ORDER BY 
    r.r_regionkey, sr.sale_rank;
