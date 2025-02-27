WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        ss.total_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        ss.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                SupplierSales
        )
),
RankedRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT n.n_nationkey) DESC) AS region_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    fr.s_suppkey,
    fr.s_name,
    fr.n_name,
    rr.r_name AS region_name,
    fr.total_sales,
    COALESCE(rr.region_rank, 'No Region') AS region_rank,
    CASE 
        WHEN fr.total_sales IS NULL THEN 'No Sales'
        WHEN fr.total_sales > 10000 THEN 'High Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    FilteredSuppliers fr
LEFT OUTER JOIN 
    RankedRegions rr ON fr.s_nationkey = rr.region_rank
WHERE 
    fr.total_sales BETWEEN (SELECT MIN(total_sales) FROM SupplierSales) AND (SELECT MAX(total_sales) FROM SupplierSales)
ORDER BY 
    fr.total_sales DESC, 
    fr.s_name ASC;
