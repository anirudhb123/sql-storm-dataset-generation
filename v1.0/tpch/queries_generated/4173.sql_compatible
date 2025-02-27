
WITH RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(rs.total_sales) AS region_sales
    FROM 
        region r
    LEFT JOIN 
        RegionalSales rs ON rs.n_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = r.r_regionkey
        )
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tr.r_name,
    COALESCE(tr.region_sales, 0) AS total_region_sales,
    COALESCE(tr.region_sales / NULLIF(SUM(tr.region_sales) OVER (), 0), 0) AS sales_percentage,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = tr.r_regionkey)) AS customer_count
FROM 
    TopRegions tr
WHERE 
    tr.region_sales IS NOT NULL
ORDER BY 
    total_region_sales DESC
FETCH FIRST 10 ROWS ONLY;
