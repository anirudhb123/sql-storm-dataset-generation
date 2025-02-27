WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        o.o_orderstatus IN ('O', 'P')
        AND l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY 
        r.r_name
),
SalesStats AS (
    SELECT 
        region_name,
        total_sales,
        orders_count,
        sales_rank,
        LAG(total_sales) OVER (ORDER BY sales_rank) AS previous_sales,
        LEAD(total_sales) OVER (ORDER BY sales_rank) AS next_sales
    FROM 
        RegionalSales
),
FinalStats AS (
    SELECT 
        region_name,
        total_sales,
        orders_count,
        sales_rank,
        COALESCE(previous_sales, 0) AS previous_sales,
        COALESCE(next_sales, 0) AS next_sales,
        CASE 
            WHEN total_sales > COALESCE(previous_sales, 0) THEN 'Increased'
            WHEN total_sales < COALESCE(previous_sales, 0) THEN 'Decreased'
            ELSE 'Unchanged'
        END AS sales_trend
    FROM 
        SalesStats
)
SELECT 
    f.region_name,
    f.total_sales,
    f.orders_count,
    f.sales_rank,
    f.sales_trend,
    CASE 
        WHEN f.orders_count = 0 THEN NULL
        ELSE ROUND(f.total_sales / f.orders_count, 2) 
    END AS avg_sales_per_order,
    STUFF((SELECT ',' + s.s_name
           FROM supplier s 
           JOIN partsupp ps2 ON s.s_suppkey = ps2.ps_suppkey
           JOIN part p2 ON ps2.ps_partkey = p2.p_partkey
           WHERE p2.p_mfgr LIKE 'Manufacturer%'
           AND s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = f.region_name)
           FOR XML PATH('')), 1, 1, '') AS suppliers_list
FROM 
    FinalStats f
WHERE 
    f.sales_rank <= 5
ORDER BY 
    total_sales DESC;
