WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
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
        o.o_orderstatus = 'F' -- Filtering for completed orders
    GROUP BY 
        r.r_name
),
SalesRanked AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    sr.region_name,
    sr.total_sales,
    sr.order_count,
    COALESCE(p.p_brand, 'Unknown') AS part_brand,
    p.p_type,
    CASE 
        WHEN sr.total_sales > 1000000 THEN 'High'
        WHEN sr.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    SalesRanked sr
LEFT JOIN 
    part p ON EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
        AND p.p_partkey = l.l_partkey
    )
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.total_sales DESC
UNION ALL
SELECT 
    'TOTAL' as region_name,
    SUM(total_sales) AS total_sales,
    SUM(order_count) AS order_count,
    NULL AS part_brand,
    NULL AS part_type,
    NULL AS sales_category
FROM 
    SalesRanked;
