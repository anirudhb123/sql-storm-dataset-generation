WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name,
        ss.s_name,
        ss.total_sales
    FROM 
        SupplierSales ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
    WHERE 
        ss.sales_rank <= 3
),
RegionSuppliers AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(ts.total_sales), 0) AS total_region_sales
    FROM 
        region r
    LEFT JOIN 
        (SELECT DISTINCT n_regionkey FROM nation) n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        TopSuppliers ts ON n.n_name = ts.n_name
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.total_region_sales,
    CASE 
        WHEN r.total_region_sales > 100000 THEN 'High Value'
        WHEN r.total_region_sales BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    RegionSuppliers r
WHERE 
    r.total_region_sales IS NOT NULL
ORDER BY 
    r.total_region_sales DESC
UNION
SELECT 
    'All Regions' AS r_name,
    SUM(total_region_sales) AS total_region_sales,
    CASE 
        WHEN SUM(total_region_sales) > 100000 THEN 'High Value'
        WHEN SUM(total_region_sales) BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    RegionSuppliers;
