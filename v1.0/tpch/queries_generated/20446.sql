WITH BaseSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_tax) AS total_tax,
        MAX(CASE WHEN l.l_shipdate < '1996-01-01' THEN l.l_returnflag END) AS first_return_flag
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate < CURRENT_DATE
    GROUP BY 
        o.o_orderkey
),
SupplierRegion AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
SalesRanked AS (
    SELECT 
        bs.o_orderkey,
        bs.total_sales,
        DENSE_RANK() OVER (PARTITION BY bs.first_return_flag ORDER BY bs.total_sales DESC) AS sales_rank
    FROM 
        BaseSales bs
)
SELECT 
    sr.nation_name,
    sr.region_name,
    sr.supplier_count,
    COALESCE(SUM(sr.supplier_count / NULLIF(s.sales_rank, 0)), 0) AS adjusted_supplier_count,
    COALESCE(AVG(s.total_sales), 0) AS avg_sales,
    COUNT(DISTINCT s.o_orderkey) AS total_orders_completed
FROM 
    SupplierRegion sr
LEFT JOIN 
    SalesRanked s ON sr.nation_name = COALESCE(NULLIF(s.o_orderkey, ''), 'UNKNOWN')
WHERE 
    sr.supplier_count > 0 AND 
    (sr.region_name IS NOT NULL OR sr.region_name IS NULL) 
GROUP BY 
    sr.nation_name, sr.region_name
HAVING 
    adjusted_supplier_count > 0 AND 
    avg_sales > 1000
ORDER BY 
    adjusted_supplier_count DESC, 
    avg_sales ASC;
