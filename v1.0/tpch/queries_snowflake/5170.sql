WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
), RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_sales,
        COUNT(DISTINCT ss.total_orders) AS total_orders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierSales ss ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ss.s_suppkey)
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.region_sales,
    r.total_orders,
    SUM(r.region_sales) OVER () AS grand_total_sales
FROM 
    RegionSales r
ORDER BY 
    r.region_sales DESC;
