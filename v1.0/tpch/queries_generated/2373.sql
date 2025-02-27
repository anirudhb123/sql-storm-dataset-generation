WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_regionkey,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rs.region_name,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales,
    COALESCE(SUM(ss.order_count), 0) AS total_orders,
    AVG(ss.total_sales) OVER (PARTITION BY rs.region_name) AS avg_sales_per_supplier
FROM 
    RegionNation rs
LEFT JOIN 
    SupplierSales ss ON rs.n_nationkey IN (
        SELECT s.n_nationkey 
        FROM supplier s 
        WHERE s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps)
    )
GROUP BY 
    rs.region_name
ORDER BY 
    total_sales DESC, rs.region_name;
