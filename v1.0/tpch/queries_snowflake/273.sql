
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),

RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        SupplierSales ss ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey)
    GROUP BY 
        n.n_regionkey, r.r_name
),

FilteredSales AS (
    SELECT 
        r.r_name,
        r.region_total_sales,
        ROW_NUMBER() OVER (ORDER BY r.region_total_sales DESC) AS sales_rank
    FROM 
        RegionSales r
    WHERE 
        r.region_total_sales IS NOT NULL
)

SELECT 
    f.r_name,
    f.region_total_sales,
    COALESCE(f2.region_total_sales, 0) AS next_region_sales
FROM 
    FilteredSales f
LEFT JOIN 
    FilteredSales f2 ON f.sales_rank = f2.sales_rank - 1
WHERE 
    f.region_total_sales > (SELECT AVG(region_total_sales) FROM FilteredSales)
ORDER BY 
    f.region_total_sales DESC;
