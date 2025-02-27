WITH RECURSIVE RegionSales AS (
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
        COALESCE(SUM(rs.total_sales), 0) AS region_sales
    FROM 
        region r
    LEFT JOIN 
        RegionSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.n_nationkey)
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COALESCE(SUM(rs.total_sales), 0) > 1000000
    ORDER BY 
        region_sales DESC
)

SELECT 
    tr.r_name AS region_name,
    tr.region_sales AS total_region_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    TopRegions tr
LEFT JOIN 
    orders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year')
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey 
GROUP BY 
    tr.r_name, tr.region_sales
ORDER BY 
    region_sales DESC;